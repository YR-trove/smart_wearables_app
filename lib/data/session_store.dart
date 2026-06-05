import 'dart:async';
import 'package:flutter/foundation.dart';
import 'database/session_dao.dart';
import 'database/user_dao.dart';
import 'models/imu_sample.dart';
import 'models/light_sample.dart';
import 'models/mic_sample.dart';
import 'models/session_model.dart';
import 'models/session_summary.dart';
import 'models/user_profile.dart';

/// Central in-memory state for the active session.
/// Also owns the pending write queues and the 5-second flush timer.
/// Extends ChangeNotifier so pages can rebuild via Provider.
class SessionStore extends ChangeNotifier {
  final _sessionDao = SessionDao();
  final _userDao    = UserDao();

  // ── Active entities ───────────────────────────────────────────────────────
  UserProfile?  currentUser;
  SessionModel? currentSession;

  // ── Live metrics (updated every packet, never written raw to DB) ──────────
  int    stepCount        = 0;
  double noiseLevel       = 0.0;  // dB, latest reading
  double noiseDosePercent = 0.0;  // 0.0–1.0
  double blueLightRatio   = 0.0;
  double uvRisk           = 0.0;
  double sunLikeIndex     = 0.0;

  // ── Accumulated metrics (checkpointed to session_summary) ────────────────
  double peakNoiseDb       = 0.0;
  double blueLightDose     = 0.0;
  double noiseExposureSec  = 0.0;
  double _uvRiskSum        = 0.0;
  double _sunLikeSum       = 0.0;
  int    _lightSampleCount = 0;

  // ── Pending write queues (flushed every 5 s) ─────────────────────────────
  final List<ImuSample>   _pendingImu   = [];
  final List<LightSample> _pendingLight = [];
  final List<MicSample>   _pendingMic   = [];

  Timer? _flushTimer;
  Timer? _checkpointTimer;

  // ── Date/time helpers ─────────────────────────────────────────────────────
  DateTime get now           => DateTime.now();
  String   get formattedDate => '${now.day.toString().padLeft(2,'0')}/${now.month.toString().padLeft(2,'0')}/${now.year}';
  String   get formattedTime => '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}';

  // ── Initialisation ────────────────────────────────────────────────────────

  /// Call once at app start (after WidgetsFlutterBinding.ensureInitialized).
  Future<void> init() async {
    // Load the first available user, if any.
    final users = await _userDao.findAll();
    if (users.isNotEmpty) {
      currentUser = users.first;
      await _recoverCrashedSession(currentUser!.id!);
    }
  }

  // ── User management ───────────────────────────────────────────────────────

  Future<void> createUser({
    required String name,
    int? age,
    double? weightKg,
    double? heightCm,
  }) async {
    final profile = UserProfile(
      name: name,
      ageYears: age,
      weightKg: weightKg,
      heightCm: heightCm,
      createdAt: DateTime.now().toIso8601String(),
    );
    currentUser = await _userDao.insert(profile);
    notifyListeners();
  }

  Future<void> updateUser(UserProfile updated) async {
    await _userDao.update(updated);
    currentUser = updated;
    notifyListeners();
  }

  Future<List<UserProfile>> getAllUsers() => _userDao.findAll();

  Future<void> switchUser(int userId) async {
    // End current session before switching.
    if (currentSession != null) await endSession();
    currentUser = await _userDao.findById(userId);
    if (currentUser != null) {
      await _recoverCrashedSession(currentUser!.id!);
    }
    notifyListeners();
  }

  // ── Session lifecycle ─────────────────────────────────────────────────────

  Future<void> startSession(String deviceId) async {
    assert(currentUser?.id != null, 'A user must be selected before starting a session');
    final session = SessionModel(
      userId: currentUser!.id!,
      deviceId: deviceId,
      startedAt: DateTime.now().toIso8601String(),
    );
    currentSession = await _sessionDao.insert(session);
    _resetAccumulators();
    _startTimers();
    notifyListeners();
  }

  Future<void> endSession() async {
    final session = currentSession;
    if (session == null) return;

    _stopTimers();
    await _flush();                                      // write remaining queued data
    await _saveCheckpoint();                             // write final summary
    await _sessionDao.closeSession(
      session.id!,
      DateTime.now().toIso8601String(),
    );
    currentSession = null;
    notifyListeners();
  }

  /// Resumes an active session after a crash or unexpected app close.
  Future<void> _recoverCrashedSession(int userId) async {
    final orphan = await _sessionDao.findActiveSession(userId);
    if (orphan == null) return;

    currentSession = orphan;
    final summary = await _sessionDao.findSummary(orphan.id!);
    if (summary != null) {
      stepCount        = summary.totalSteps;
      peakNoiseDb      = summary.peakNoiseDb;
      noiseDosePercent = summary.noiseDosePct;
      noiseExposureSec = summary.noiseExposureSec;
      blueLightDose    = summary.blueLightDose;
      uvRisk           = summary.avgUvRisk;
      sunLikeIndex     = summary.avgSunLikeIndex;
    }
    _startTimers();
    notifyListeners();
  }

  Future<List<SessionModel>> getSessionsForCurrentUser() async {
    if (currentUser?.id == null) return [];
    return _sessionDao.findByUser(currentUser!.id!);
  }

  // ── Packet handlers ───────────────────────────────────────────────────────

  void onImuPacket(ImuSample s) {
    stepCount = s.stepCount;
    _pendingImu.add(s);
    notifyListeners();
  }

  void onLightPacket(LightSample s) {
    uvRisk           = s.uvRisk;
    blueLightRatio   = s.blueLightRatio;
    sunLikeIndex     = s.sunLikeIndex;
    blueLightDose   += s.blueLightIntensity;
    _uvRiskSum      += s.uvRisk;
    _sunLikeSum     += s.sunLikeIndex;
    _lightSampleCount++;
    _pendingLight.add(s);
    notifyListeners();
  }

  void onMicPacket(MicSample s) {
    noiseLevel       = s.noiseLevel;
    noiseExposureSec = s.noiseTime;
    if (s.noiseLevel > peakNoiseDb) peakNoiseDb = s.noiseLevel;
    // NIOSH/WHO simplified dose: t_exposed / t_allowed(85dB=28800s)
    noiseDosePercent = (noiseExposureSec / 28800.0).clamp(0.0, 1.0);
    _pendingMic.add(s);
    notifyListeners();
  }

  // ── Timers ────────────────────────────────────────────────────────────────

  void _startTimers() {
    _flushTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _flush(),
    );
    _checkpointTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _saveCheckpoint(),
    );
  }

  void _stopTimers() {
    _flushTimer?.cancel();
    _checkpointTimer?.cancel();
    _flushTimer = null;
    _checkpointTimer = null;
  }

  // ── DB writes ─────────────────────────────────────────────────────────────

  Future<void> _flush() async {
    final id = currentSession?.id;
    if (id == null) return;

    if (_pendingImu.isNotEmpty) {
      final batch = List<ImuSample>.from(_pendingImu);
      _pendingImu.clear();
      await _sessionDao.flushImu(id, batch);
    }
    if (_pendingLight.isNotEmpty) {
      final batch = List<LightSample>.from(_pendingLight);
      _pendingLight.clear();
      await _sessionDao.flushLight(id, batch);
    }
    if (_pendingMic.isNotEmpty) {
      final batch = List<MicSample>.from(_pendingMic);
      _pendingMic.clear();
      await _sessionDao.flushMic(id, batch);
    }
  }

  Future<void> _saveCheckpoint() async {
    final id = currentSession?.id;
    if (id == null) return;
    final summary = SessionSummary(
      sessionId: id,
      totalSteps: stepCount,
      peakNoiseDb: peakNoiseDb,
      noiseDosePct: noiseDosePercent,
      noiseExposureSec: noiseExposureSec,
      blueLightDose: blueLightDose,
      avgUvRisk: _lightSampleCount > 0 ? _uvRiskSum / _lightSampleCount : 0.0,
      avgSunLikeIndex: _lightSampleCount > 0 ? _sunLikeSum / _lightSampleCount : 0.0,
    );
    await _sessionDao.upsertSummary(summary);
  }

  void _resetAccumulators() {
    stepCount = 0; noiseLevel = 0; noiseDosePercent = 0;
    peakNoiseDb = 0; blueLightDose = 0; noiseExposureSec = 0;
    uvRisk = 0; sunLikeIndex = 0; blueLightRatio = 0;
    _uvRiskSum = 0; _sunLikeSum = 0; _lightSampleCount = 0;
    _pendingImu.clear(); _pendingLight.clear(); _pendingMic.clear();
  }

  @override
  void dispose() {
    _stopTimers();
    super.dispose();
  }
}
