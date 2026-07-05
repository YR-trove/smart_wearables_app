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
  int    _colorTemp             = 0;

  int    get sunlightSeconds       => _sunlightSeconds ~/ 1000;
  int    get nightBlueLightSeconds => _nightBlueLightSeconds ~/ 1000;
  String get skinBurnRisk          => _skinBurnRisk;
  int    get circadianScore        => _circadianScore;
  String get lightExposureLabel    => _lightExposureLabel;
  int    get blueClearRatio        => _blueClearRatio;
  int    get latestColorTemp       => _colorTemp;

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
    String? gender,
    int?    age,
    double? weightKg,
    double? heightCm,
  }) async {
    final user = await _userDao.insert(UserProfile(
      name:      name,
      gender:    gender,
      age:       age,
      weightKg:  weightKg,
      heightCm:  heightCm,
      createdAt: DateTime.now(),
    ));
    _currentUser = user;
    notifyListeners();
  }

  Future<void> updateCurrentUser({
    String? name,
    String? gender,
    int?    age,
    double? weightKg,
    double? heightCm,
  }) async {
    if (_currentUser == null) return;
    
    final updated = _currentUser!.copyWith(
      name:     name,
      gender:   gender,
      age:      age,
      weightKg: weightKg,
      heightCm: heightCm,
    );
    
    await _userDao.update(updated);
    _currentUser = updated;
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
    _colorTemp             = 0;

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

    if (_latestUnifiedPacket != null) {
      final oldSteps = _latestUnifiedPacket!.stepCount;
      final newSteps = packet.stepCount;
      
      int stepDiff = newSteps - oldSteps;
      if (stepDiff < 0) stepDiff += 65536; // Handle 16-bit hardware counter overflow

      if (stepDiff > 0) {
        _currentSteps += stepDiff;
        _activityState = 1;

        // Distance in km: Step length is roughly Height(cm) * 0.414.
        final heightCm = _currentUser?.heightCm ?? 170.0;
        _distanceKm = (_currentSteps * heightCm * 0.414) / 100000.0;

        // BMR Calculation using Mifflin-St Jeor equation
        final weightKg = _currentUser?.weightKg ?? 70.0;
        final age = _currentUser?.age ?? 30;
        final gender = _currentUser?.gender?.toLowerCase() ?? 'male';

        double bmr;
        if (gender == 'female') {
          bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
        } else {
          bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
        }

        final met = 3.5; // Active walking

        // BMR is calories per day. Convert to calories per minute.
        final bmrPerMin = bmr / 1440.0;
        
        // Calories burned per minute = MET * BMR per minute
        final kcalPerMin = met * bmrPerMin;

        // Assuming an average cadence of 100 steps per minute while active:
        final kcalPerStep = kcalPerMin / 100.0;

        _totalKcal += (kcalPerStep * stepDiff);
      } else {
        _activityState = 0;
      }
    } else {
      _activityState = 0;
    }
    
    _latestUnifiedPacket = packet;
    
    if (_stepsHistory.length >= _maxBufferSize) {
      _stepsHistory.removeAt(0);
      _activityHistory.removeAt(0);
    }
    _stepsHistory.add(_currentSteps.toDouble());
    _activityHistory.add(_activityState.toDouble());

    // -- Light Logic
    _lightExposureLabel = packet.lightClass.label;
    _blueClearRatio     = packet.blueClearRatio;
    _colorTemp          = packet.colorTemp;

    // Sunlight accumulation
    if (packet.lightClass == LightExposureClass.veryBright ||
        packet.lightClass == LightExposureClass.bright) {
      // The stream is 2 Hz, so we accumulate 0.5 seconds per packet
      _sunlightSeconds += 500; // storing ms internally now
    }

    // Night blue-light heuristic
    final hour = DateTime.now().hour;
    if (hour >= 19 &&
        packet.blueClearRatio > 3000 &&
        (packet.lightClass == LightExposureClass.bright ||
         packet.lightClass == LightExposureClass.veryBright)) {
      _nightBlueLightSeconds += 500; // storing ms internally now
      if ((_nightBlueLightSeconds ~/ 1000) % 300 == 0 && _circadianScore > 0) {
        // Decrement score every 5 minutes (300 seconds)
        // Ensure we only do this once per 300s window by tracking if we already decremented
        // Actually, a simpler way is just to recalculate it from the total.
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
