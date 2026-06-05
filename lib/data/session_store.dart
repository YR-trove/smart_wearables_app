import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:smart_wearables_app/data/database/app_database.dart';
import 'package:smart_wearables_app/data/database/session_dao.dart';
import 'package:smart_wearables_app/data/database/user_dao.dart';
import 'package:smart_wearables_app/data/models/imu_sample.dart';
import 'package:smart_wearables_app/data/models/light_sample.dart';
import 'package:smart_wearables_app/data/models/mic_sample.dart';
import 'package:smart_wearables_app/data/models/session_model.dart';
import 'package:smart_wearables_app/data/models/session_summary.dart';
import 'package:smart_wearables_app/data/models/user_profile.dart';

/// Central state manager for sessions, users, and buffered sensor data.
/// Provided via [ChangeNotifierProvider] at the app root.
class SessionStore extends ChangeNotifier {
  // DAO layer — no-arg constructors; they use AppDatabase.instance internally.
  final _userDao    = UserDao();
  final _sessionDao = SessionDao();

  // Current state
  UserProfile?  _currentUser;
  SessionModel? _activeSession;

  // In-memory flush buffers
  final List<ImuSample>   _imuBuffer   = [];
  final List<LightSample> _lightBuffer = [];
  final List<MicSample>   _micBuffer   = [];

  // Running aggregates for checkpoint summary
  int    _totalSteps    = 0;
  double _peakNoiseDb   = 0;
  double _noiseDosePct  = 0;
  double _noiseExpSec   = 0;
  double _blueLightDose = 0;
  double _sumUvRisk     = 0;
  double _sumSunLike    = 0;
  int    _lightCount    = 0;

  // Flush / checkpoint timers
  Timer? _flushTimer;
  Timer? _checkpointTimer;

  // ── Public getters ────────────────────────────────────────────────────────

  UserProfile?  get currentUser      => _currentUser;
  SessionModel? get activeSession    => _activeSession;
  bool          get hasActiveSession => _activeSession != null;

  // ── Initialisation ────────────────────────────────────────────────────────

  Future<void> init() async {
    // Warm up the DB (opens the file if not already open).
    await AppDatabase.instance.db;

    // Crash recovery: close any session that was left open.
    final orphan = await _sessionDao.findIncompleteSession();
    if (orphan != null) {
      debugPrint('SessionStore: recovering orphan session ${orphan.id}');
      await _sessionDao.closeSession(orphan.id!, DateTime.now());
    }
  }

  // ── User management ───────────────────────────────────────────────────────

  /// Returns every user profile stored in the DB.
  Future<List<UserProfile>> getAllUsers() => _userDao.findAll();

  /// Creates a new user, persists it, and sets it as the current user.
  Future<void> createUser({
    required String name,
    int?    age,
    double? weightKg,
    double? heightCm,
  }) async {
    final profile = UserProfile(
      name: name, age: age, weightKg: weightKg, heightCm: heightCm);
    final saved = await _userDao.insert(profile);
    _currentUser = saved;
    notifyListeners();
  }

  /// Loads an existing user from the DB and sets it as current.
  Future<void> switchUser(int userId) async {
    final user = await _userDao.findById(userId);
    if (user == null) throw ArgumentError('User $userId not found');
    _currentUser = user;
    notifyListeners();
  }

  // ── Session lifecycle ─────────────────────────────────────────────────────

  Future<void> startSession(String deviceId) async {
    assert(_currentUser != null, 'Call switchUser() or createUser() first.');
    if (_activeSession != null) return;

    final session = SessionModel(
      userId:    _currentUser!.id!,
      deviceId:  deviceId,
      startedAt: DateTime.now(),
      isActive:  true,
    );
    // insert() now returns the model with its DB-generated id.
    final saved = await _sessionDao.insert(session);
    _activeSession = saved;

    // Reset running aggregates for the new session.
    _totalSteps = 0; _peakNoiseDb = 0; _noiseDosePct = 0;
    _noiseExpSec = 0; _blueLightDose = 0;
    _sumUvRisk = 0; _sumSunLike = 0; _lightCount = 0;

    _flushTimer = Timer.periodic(
        const Duration(seconds: 5), (_) => _flush());
    _checkpointTimer = Timer.periodic(
        const Duration(seconds: 30), (_) => _checkpoint());

    notifyListeners();
  }

  Future<void> endSession() async {
    if (_activeSession == null) return;

    _flushTimer?.cancel();
    _checkpointTimer?.cancel();

    await _flush();
    await _checkpoint();

    await _sessionDao.closeSession(_activeSession!.id!, DateTime.now());
    _activeSession = null;
    notifyListeners();
  }

  // ── Packet handlers ───────────────────────────────────────────────────────

  void onImuPacket(ImuSample sample) {
    if (_activeSession == null) return;
    _imuBuffer.add(sample);
    if (sample.type == 'A' && sample.stepCount != null) {
      _totalSteps = sample.stepCount!;  // firmware sends cumulative count
    }
  }

  void onLightPacket(LightSample sample) {
    if (_activeSession == null) return;
    _lightBuffer.add(sample);
    _sumUvRisk    += sample.uvRisk;
    _sumSunLike   += sample.sunLikeIndex;
    _blueLightDose += sample.blueLightIntensity;
    _lightCount++;
  }

  void onMicPacket(MicSample sample) {
    if (_activeSession == null) return;
    _micBuffer.add(sample);
    if (sample.noiseLevel > _peakNoiseDb) _peakNoiseDb = sample.noiseLevel;
    // Accumulate noise exposure time (noiseTime is in seconds per packet).
    _noiseExpSec += sample.noiseTime;
    // Simple dose: fraction of 8h at 85 dB (OSHA TWA)
    const double refExposureSec = 8 * 3600;
    _noiseDosePct = _noiseExpSec / refExposureSec;
  }

  // ── Internal flush & checkpoint ───────────────────────────────────────────

  Future<void> _flush() async {
    if (_activeSession == null) return;
    final sid = _activeSession!.id!;

    if (_imuBuffer.isNotEmpty) {
      await _sessionDao.flushImu(sid, List.of(_imuBuffer));
      _imuBuffer.clear();
    }
    if (_lightBuffer.isNotEmpty) {
      await _sessionDao.flushLight(sid, List.of(_lightBuffer));
      _lightBuffer.clear();
    }
    if (_micBuffer.isNotEmpty) {
      await _sessionDao.flushMic(sid, List.of(_micBuffer));
      _micBuffer.clear();
    }
  }

  Future<void> _checkpoint() async {
    if (_activeSession == null) return;
    final summary = SessionSummary(
      sessionId:        _activeSession!.id!,
      totalSteps:       _totalSteps,
      peakNoiseDb:      _peakNoiseDb,
      noiseDosePct:     _noiseDosePct,
      noiseExposureSec: _noiseExpSec,
      blueLightDose:    _blueLightDose,
      avgUvRisk:        _lightCount > 0 ? _sumUvRisk  / _lightCount : 0,
      avgSunLikeIndex:  _lightCount > 0 ? _sumSunLike / _lightCount : 0,
    );
    await _sessionDao.upsertSummary(summary);
  }

  @override
  void dispose() {
    _flushTimer?.cancel();
    _checkpointTimer?.cancel();
    super.dispose();
  }
}
