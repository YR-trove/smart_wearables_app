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
  // DAO layer
  late final AppDatabase  _db;
  late final UserDao      _userDao;
  late final SessionDao   _sessionDao;

  // Current state
  UserProfile?  _currentUser;
  SessionModel? _activeSession;

  // In-memory flush buffers
  final List<ImuSample>   _imuBuffer   = [];
  final List<LightSample> _lightBuffer = [];
  final List<MicSample>   _micBuffer   = [];

  // Flush / checkpoint timers
  Timer? _flushTimer;
  Timer? _checkpointTimer;

  // ── Public getters ───────────────────────────────────────────────

  UserProfile?  get currentUser    => _currentUser;
  SessionModel? get activeSession  => _activeSession;
  bool          get hasActiveSession => _activeSession != null;

  // ── Initialisation ──────────────────────────────────────────────

  Future<void> init() async {
    _db         = await AppDatabase.instance;
    _userDao    = UserDao(_db);
    _sessionDao = SessionDao(_db);

    // Crash recovery: close any session that was left open.
    final orphan = await _sessionDao.findIncompleteSession();
    if (orphan != null) {
      debugPrint('SessionStore: recovering orphan session ${orphan.id}');
      await _sessionDao.closeSession(orphan.id!, DateTime.now());
    }
  }

  // ── User management ─────────────────────────────────────────────

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
      name:     name,
      age:      age,
      weightKg: weightKg,
      heightCm: heightCm,
    );
    final id = await _userDao.insert(profile);
    _currentUser = profile.copyWith(id: id);
    notifyListeners();
  }

  /// Loads an existing user from the DB and sets it as current.
  Future<void> switchUser(int userId) async {
    final user = await _userDao.findById(userId);
    if (user == null) throw ArgumentError('User $userId not found');
    _currentUser = user;
    notifyListeners();
  }

  // ── Session lifecycle ───────────────────────────────────────────

  Future<void> startSession(String deviceId) async {
    assert(_currentUser != null, 'Call switchUser() or createUser() first.');
    if (_activeSession != null) return; // Already running.

    final session = SessionModel(
      userId:    _currentUser!.id!,
      deviceId:  deviceId,
      startedAt: DateTime.now(),
      isActive:  true,
    );
    final id = await _sessionDao.insertSession(session);
    _activeSession = session.copyWith(id: id);

    // 5s flush: writes buffered samples to DB and clears the lists.
    _flushTimer = Timer.periodic(const Duration(seconds: 5), (_) => _flush());

    // 30s checkpoint: upserts a rolling summary row.
    _checkpointTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _checkpoint());

    notifyListeners();
  }

  Future<void> endSession() async {
    if (_activeSession == null) return;

    _flushTimer?.cancel();
    _checkpointTimer?.cancel();

    await _flush();          // Final flush of remaining samples.
    await _checkpoint();     // Final summary snapshot.

    await _sessionDao.closeSession(_activeSession!.id!, DateTime.now());
    _activeSession = null;
    notifyListeners();
  }

  // ── Packet handlers ──────────────────────────────────────────────
  // Called from MainShell for every validated packet.

  void onImuPacket(ImuSample sample) {
    if (_activeSession == null) return;
    _imuBuffer.add(sample);
  }

  void onLightPacket(LightSample sample) {
    if (_activeSession == null) return;
    _lightBuffer.add(sample);
  }

  void onMicPacket(MicSample sample) {
    if (_activeSession == null) return;
    _micBuffer.add(sample);
  }

  // ── Internal flush & checkpoint ───────────────────────────────────

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
      sessionId:    _activeSession!.id!,
      updatedAt:    DateTime.now(),
      totalImuRows:   await _sessionDao.countImu(_activeSession!.id!),
      totalLightRows: await _sessionDao.countLight(_activeSession!.id!),
      totalMicRows:   await _sessionDao.countMic(_activeSession!.id!),
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
