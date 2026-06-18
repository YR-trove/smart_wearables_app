import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:smart_wearables_app/data/database/session_dao.dart';
import 'package:smart_wearables_app/data/database/user_dao.dart';
import 'package:smart_wearables_app/data/models/session_model.dart';
import 'package:smart_wearables_app/data/models/unified_telemetry.dart';
import 'package:smart_wearables_app/data/models/user_profile.dart';

/// Central state manager for user, session, and live telemetry.
///
/// The MCU transmits a 1 Hz unified state packet (0x55) containing fused
/// IMU kinematics and AS7341 spectral light data. On every packet:
///   1. Decode via [onUnifiedPacket].
///   2. Write to DB immediately (single INSERT, no batching needed).
///   3. Update [latestTelemetry] and notify listeners for UI refresh.
class SessionStore extends ChangeNotifier {
  final SessionDao _sessionDao;
  final UserDao    _userDao;

  SessionStore({
    SessionDao? sessionDao,
    UserDao?    userDao,
  })  : _sessionDao = sessionDao ?? SessionDao(),
        _userDao    = userDao    ?? UserDao();

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  UserProfile?      _currentUser;
  SessionModel?     _activeSession;
  UnifiedTelemetry? _latestTelemetry;

  UserProfile?      get currentUser      => _currentUser;
  SessionModel?     get activeSession    => _activeSession;
  /// The most recently received + persisted telemetry snapshot.
  UnifiedTelemetry? get latestTelemetry  => _latestTelemetry;

  // ---------------------------------------------------------------------------
  // Initialisation — crash recovery
  // ---------------------------------------------------------------------------

  Future<void> init() async {
    final orphan = await _sessionDao.findIncompleteSession();
    if (orphan != null) {
      debugPrint('SessionStore: closing orphaned session ${orphan.id}');
      await _sessionDao.closeSession(orphan.id!, DateTime.now());
    }
  }

  // ---------------------------------------------------------------------------
  // User management
  // ---------------------------------------------------------------------------

  Future<List<UserProfile>> getAllUsers() => _userDao.findAll();

  Future<void> createUser({
    required String name,
    int?    age,
    double? weightKg,
    double? heightCm,
  }) async {
    final user = await _userDao.insert(UserProfile(
      name:      name,
      age:       age,
      weightKg:  weightKg,
      heightCm:  heightCm,
      createdAt: DateTime.now(),
    ));
    _currentUser = user;
    notifyListeners();
  }

  Future<void> switchUser(int userId) async {
    _currentUser = await _userDao.findById(userId);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Session lifecycle
  // ---------------------------------------------------------------------------

  Future<void> startSession(String deviceId) async {
    assert(_currentUser != null, 'A user must be selected before starting a session.');
    _activeSession = await _sessionDao.insert(SessionModel(
      userId:    _currentUser!.id!,
      deviceId:  deviceId,
      startedAt: DateTime.now(),
      isActive:  true,
    ));
    _latestTelemetry = null;
    notifyListeners();
    debugPrint('SessionStore: session ${_activeSession!.id} started.');
  }

  Future<void> endSession() async {
    if (_activeSession == null) return;
    await _sessionDao.closeSession(_activeSession!.id!, DateTime.now());
    debugPrint('SessionStore: session ${_activeSession!.id} closed.');
    _activeSession = null;
    _latestTelemetry = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Unified 1 Hz packet handler
  // ---------------------------------------------------------------------------

  /// Decodes a pre-validated 20-byte [0x55] payload into [UnifiedTelemetry],
  /// persists it immediately, and updates [latestTelemetry] for the UI.
  ///
  /// [rawData] must already pass frame validation (length == 20,
  /// data[0] == 0x7B, data[19] == 0x7D, data[1] == 0x55).
  Future<void> onUnifiedPacket(List<int> rawData) async {
    if (_activeSession == null) return;

    final payload  = Uint8List.fromList(rawData);
    final bd       = ByteData.sublistView(payload);
    final ts       = DateTime.now();

    final row = UnifiedTelemetry(
      sessionId:          _activeSession!.id!,
      tsMs:               ts.millisecondsSinceEpoch,
      stepCount:          bd.getUint16(2,  Endian.little),
      cadence:            bd.getUint8(4),
      activityState:      bd.getUint8(5),
      uvRisk:             bd.getUint16(6,  Endian.little) / 32767.0,
      blueLightIntensity: bd.getUint16(8,  Endian.little),
      blueLightRatio:     bd.getUint16(10, Endian.little) / 32767.0,
      sunLikeIndex:       bd.getUint16(12, Endian.little) / 32767.0,
      clearChannel:       bd.getUint16(14, Endian.little),
    );

    await _sessionDao.insertUnified(row);
    _latestTelemetry = row;
    notifyListeners();
  }
}
