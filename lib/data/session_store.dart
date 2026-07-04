import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:smart_wearables_app/data/database/session_dao.dart';
import 'package:smart_wearables_app/data/database/user_dao.dart';
import 'package:smart_wearables_app/data/models/live_packets.dart';
import 'package:smart_wearables_app/data/models/session_model.dart';
import 'package:smart_wearables_app/data/models/user_profile.dart';

class SessionStore extends ChangeNotifier {
  final SessionDao _sessionDao;
  final UserDao    _userDao;

  SessionStore({
    SessionDao? sessionDao,
    UserDao?    userDao,
  })  : _sessionDao = sessionDao ?? SessionDao(),
        _userDao    = userDao    ?? UserDao();

  // ─── Core state ────────────────────────────────────────────────────────────

  UserProfile?    _currentUser;
  SessionModel?   _activeSession;
  DateTime?       _sessionStartTime;

  // Latest live packets — one per type, replaced on every RX
  UnifiedLivePacket? _latestUnifiedPacket;

  UserProfile?      get currentUser      => _currentUser;
  SessionModel?     get activeSession    => _activeSession;
  DateTime?         get sessionStartTime => _sessionStartTime;
  UnifiedLivePacket? get latestUnifiedPacket => _latestUnifiedPacket;

  Duration get elapsed {
    if (_sessionStartTime == null) return Duration.zero;
    return DateTime.now().difference(_sessionStartTime!);
  }

  // ─── Fitness accumulators ──────────────────────────────────────────────────

  int    _currentSteps  = 0;
  int    _activityState = 0;   // 0=Stationary/Idle, 1=Active
  double _distanceKm    = 0.0;
  double _totalKcal     = 0.0;

  int    get currentSteps   => _currentSteps;
  int    get activityState  => _activityState;
  double get distanceKm     => _distanceKm;
  double get totalKcal      => _totalKcal;

  String get activityLabel => switch (_activityState) {
    1 => 'Active',
    _ => 'Stationary',
  };

  // ─── Audio ─────────────────────────────────────────────────────────────────

  double get latestLaeqDb     => _latestUnifiedPacket?.laeqDb             ?? 0.0;
  String get latestEnvLabel   => _latestUnifiedPacket?.audioClass.label   ?? '—';

  // ─── Light / photobiology accumulators ────────────────────────────────────

  int    _sunlightSeconds       = 0;
  int    _nightBlueLightSeconds = 0;
  String _skinBurnRisk          = 'Low';
  int    _circadianScore        = 100;
  String _lightExposureLabel    = '—';
  int    _blueClearRatio        = 0;


  int    get sunlightSeconds       => _sunlightSeconds;
  int    get nightBlueLightSeconds => _nightBlueLightSeconds;
  String get skinBurnRisk          => _skinBurnRisk;
  int    get circadianScore        => _circadianScore;
  String get lightExposureLabel    => _lightExposureLabel;
  int    get blueClearRatio        => _blueClearRatio;

  SessionDao get sessionDao => _sessionDao;

  String get blueLightExposureLevel {
    if (_nightBlueLightSeconds > 3600) return 'High';
    if (_nightBlueLightSeconds > 1800) return 'Moderate';
    return 'Low';
  }

  // ─── Dev Rolling History Buffers ──────────────────────────────────────────

  static const int _maxBufferSize = 60;

  final List<double> _stepsHistory         = [];
  final List<double> _activityHistory      = [];
  final List<double> _laeqHistory          = [];
  final List<double> _intensityHistory     = [];


  List<List<double>> get devMetricsHistory => [
    _stepsHistory,
    _activityHistory,
    _laeqHistory,
    _intensityHistory,
  ];

  // ─── Initialisation — crash recovery ──────────────────────────────────────

  Future<void> init() async {
    final orphan = await _sessionDao.findIncompleteSession();
    if (orphan != null) {
      debugPrint('SessionStore: closing orphaned session ${orphan.id}');
      await _sessionDao.closeSession(orphan.id!, DateTime.now());
    }
  }

  // ─── User management ──────────────────────────────────────────────────────

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

  // ─── Session lifecycle ────────────────────────────────────────────────────

  Future<void> startSession(String deviceId) async {
    assert(_currentUser != null, 'A user must be selected before starting a session.');
    _activeSession = await _sessionDao.insert(SessionModel(
      userId:    _currentUser!.id!,
      deviceId:  deviceId,
      startedAt: DateTime.now(),
      isActive:  true,
    ));
    _sessionStartTime = DateTime.now();
    _resetAccumulators();
    notifyListeners();
    debugPrint('SessionStore: session ${_activeSession!.id} started.');
  }

  Future<void> endSession() async {
    if (_activeSession == null) return;
    await _sessionDao.closeSession(_activeSession!.id!, DateTime.now());
    debugPrint('SessionStore: session ${_activeSession!.id} closed.');
    _activeSession    = null;
    _latestUnifiedPacket = null;
    _sessionStartTime = null;
    _resetAccumulators();
    notifyListeners();
  }

  void _resetAccumulators() {
    _currentSteps   = 0;
    _activityState  = 0;
    _distanceKm     = 0.0;
    _totalKcal      = 0.0;

    _sunlightSeconds       = 0;
    _nightBlueLightSeconds = 0;
    _skinBurnRisk          = 'Low';
    _circadianScore        = 100;
    _lightExposureLabel    = '—';
    _blueClearRatio        = 0;

    _stepsHistory.clear();
    _activityHistory.clear();
    _laeqHistory.clear();
    _intensityHistory.clear();
  }

  // ─── Live-mode packet handlers ────────────────────────────────────────────

  /// Called by MainShell on every 0x55 Unified metrics packet (2 Hz).
  Future<void> onUnifiedPacket(UnifiedLivePacket packet) async {
    if (_activeSession == null) return;

    unawaited(_sessionDao.insertUnifiedPacket(packet));

    _latestUnifiedPacket = packet;
    
    // -- IMU Logic
    int stepsDiff = packet.stepCount - _currentSteps;
    if (stepsDiff < 0) stepsDiff += 65536; // handle 16-bit overflow
    
    _activityState = (stepsDiff > 0) ? 1 : 0;
    _currentSteps  = packet.stepCount;

    final heightCm = _currentUser?.heightCm ?? 170.0;
    _distanceKm = (_currentSteps * heightCm * 0.414) / 100000.0;

    final weightKg = _currentUser?.weightKg ?? 70.0;
    final met = switch (_activityState) {
      1 => 3.5, // Active
      _ => 0.0, // Stationary
    };
    _totalKcal += (met * 3.5 * weightKg) / 12000.0;

    if (_stepsHistory.length >= _maxBufferSize) {
      _stepsHistory.removeAt(0);
      _activityHistory.removeAt(0);
    }
    _stepsHistory.add(packet.stepCount.toDouble());
    _activityHistory.add(_activityState.toDouble());

    // -- Light Logic
    _lightExposureLabel = packet.lightClass.label;
    _blueClearRatio     = packet.blueClearRatio;

    // Sunlight accumulation (Very Bright is new Outdoor/Bright equiv)
    if (packet.lightClass == LightExposureClass.veryBright ||
        packet.lightClass == LightExposureClass.bright) {
      _sunlightSeconds += 1; // 2Hz stream, roughly maybe scale? Let's just do +1
    }

    // Night blue-light heuristic
    final hour = DateTime.now().hour;
    if (hour >= 19 &&
        (packet.lightClass == LightExposureClass.moderate ||
         packet.lightClass == LightExposureClass.bright ||
         packet.lightClass == LightExposureClass.veryBright)) {
      _nightBlueLightSeconds += 1;
      if (_nightBlueLightSeconds % 300 == 0 && _circadianScore > 0) {
        _circadianScore -= 1;
      }
    }

    if (_intensityHistory.length >= _maxBufferSize) _intensityHistory.removeAt(0);
    _intensityHistory.add(packet.blueClearRatio.toDouble());

    // -- Audio Logic
    if (_laeqHistory.length >= _maxBufferSize) _laeqHistory.removeAt(0);
    _laeqHistory.add(packet.laeqDb);

    notifyListeners();
  }

  /// Called by MainShell when a 0x53 connection-event packet arrives.
  void onConnectionEvent(LiveConnectionEvent event) {
    debugPrint('SessionStore: connection event → ${event.name}');
  }

}

void unawaited(Future<void> future) {
  future.catchError((e) => debugPrint('SessionStore unawaited error: $e'));
}
