import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:smart_wearables_app/data/database/session_dao.dart';
import 'package:smart_wearables_app/data/database/user_dao.dart';
import 'package:smart_wearables_app/data/models/session_model.dart';
import 'package:smart_wearables_app/data/models/unified_telemetry.dart';
import 'package:smart_wearables_app/data/models/user_profile.dart';

class SessionStore extends ChangeNotifier {
  final SessionDao _sessionDao;
  final UserDao    _userDao;

  SessionStore({
    SessionDao? sessionDao,
    UserDao?    userDao,
  })  : _sessionDao = sessionDao ?? SessionDao(),
        _userDao    = userDao    ?? UserDao();

  // ─── Core state ─────────────────────────────────────────────────────────────

  UserProfile?      _currentUser;
  SessionModel?     _activeSession;
  UnifiedTelemetry? _latestTelemetry;
  DateTime?         _sessionStartTime;

  UserProfile?      get currentUser   => _currentUser;
  SessionModel?     get activeSession => _activeSession;
  UnifiedTelemetry? get latestTelemetry => _latestTelemetry;
  DateTime?         get sessionStartTime => _sessionStartTime;
  Duration get elapsed {
    if (_sessionStartTime == null) return Duration.zero;
    return DateTime.now().difference(_sessionStartTime!);
  }

  // ─── Fitness accumulators ────────────────────────────────────────────────────

  int    _currentSteps    = 0;
  int    _currentCadence  = 0;
  int    _activityState   = 0;   // 0=Idle, 1=Walking, 2=Running
  double _distanceKm      = 0.0;
  double _totalKcal       = 0.0;

  int    get currentSteps   => _currentSteps;
  int    get currentCadence => _currentCadence;
  int    get activityState  => _activityState;
  double get distanceKm     => _distanceKm;
  double get totalKcal      => _totalKcal;

  // ─── Audio Accumulators ──────────────────────────────────────────────────────
  double noiseDbSpl = 0.0;
  double noiseDbfs  = 0.0;

  String get activityLabel => switch (_activityState) {
    1 => 'Walking',
    2 => 'Running',
    _ => 'Idle',
  };

  // ─── Light / photobiology accumulators ──────────────────────────────────────

  int    _sunlightSeconds       = 0;
  int    _nightBlueLightSeconds = 0;
  double _currentUvIndex        = 0.0;
  String _skinBurnRisk          = 'Low';
  int    _circadianScore        = 100;
  double _currentBlueRatio      = 0.0;
  int    _colorTemp             = 0;
  double clearChannel           = 0;
  int    _noiseDbSpl            = 0;

  int    get sunlightSeconds       => _sunlightSeconds;
  int    get nightBlueLightSeconds => _nightBlueLightSeconds;
  double get currentUvIndex        => _currentUvIndex;
  String get skinBurnRisk          => _skinBurnRisk;
  int    get circadianScore        => _circadianScore;
  double get currentBlueRatio      => _currentBlueRatio;
  int    get colorTemp             => _colorTemp;
  int    get noiseDbSpl            => _noiseDbSpl;

  SessionDao get sessionDao => _sessionDao;

  String get blueLightExposureLevel {
    if (_nightBlueLightSeconds > 3600) return 'High';
    if (_nightBlueLightSeconds > 1800) return 'Moderate';
    return 'Low';
  }

  // ─── Dev Dashboard Historical Buffers ───────────────────────────────────────
  
  static const int _maxBufferSize = 60; // Holds 60 seconds of rolling history
  final List<double> _stepsHistory = [];
  final List<double> _cadenceHistory = [];
  final List<double> _activityHistory = [];
  final List<double> _uvHistory = [];
  final List<double> _blueIntensityHistory = [];
  final List<double> _blueRatioHistory = [];
  final List<double> _colorTempHistory = [];
  final List<double> _clearChannelHistory = [];
  final List<int>    _noiseDbSplHistory = [];
  // Exposes a unified historical structure directly to your custom oscilloscope painter
  List<List<double>> get devMetricsHistory => [
    _stepsHistory,
    _cadenceHistory,
    _activityHistory,
    _uvHistory,
    _blueIntensityHistory,
    _blueRatioHistory,
    _colorTempHistory,
    _clearChannelHistory,
  ];

  // ─── Initialisation — crash recovery ────────────────────────────────────────

  Future<void> init() async {
    final orphan = await _sessionDao.findIncompleteSession();
    if (orphan != null) {
      debugPrint('SessionStore: closing orphaned session ${orphan.id}');
      await _sessionDao.closeSession(orphan.id!, DateTime.now());
    }
  }

  // ─── User management ────────────────────────────────────────────────────────

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

  // ─── Session lifecycle ───────────────────────────────────────────────────────

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
    _latestTelemetry  = null;
    _sessionStartTime = null;
    _resetAccumulators();
    notifyListeners();
  }

  void _resetAccumulators() {
    _currentSteps   = 0;
    _currentCadence = 0;
    _activityState  = 0;
    _distanceKm     = 0.0;
    _totalKcal      = 0.0;
    _sunlightSeconds       = 0;
    _nightBlueLightSeconds = 0;
    _currentUvIndex        = 0.0;
    _skinBurnRisk          = 'Low';
    _circadianScore        = 100;
    _currentBlueRatio      = 0.0;
    _colorTemp             = 0;
    clearChannel           = 0;
    _noiseDbSpl            = 0;

    // Clear dev history on session reset
    _stepsHistory.clear();
    _cadenceHistory.clear();
    _activityHistory.clear();
    _uvHistory.clear();
    _blueIntensityHistory.clear();
    _blueRatioHistory.clear();
    _colorTempHistory.clear();
    _clearChannelHistory.clear();
    _noiseDbSplHistory.clear();
  }

  // ─── Unified 1 Hz packet handler ────────────────────────────────────────────

  Future<void> onUnifiedPacket(List<int> rawData) async {
    if (_activeSession == null) return;

    final payload = Uint8List.fromList(rawData);
    final bd      = ByteData.sublistView(payload);
    final ts      = DateTime.now();

    final row = UnifiedTelemetry(
      sessionId:          _activeSession!.id!,
      tsMs:               ts.millisecondsSinceEpoch,
      stepCount:          bd.getUint16(2, Endian.little),
      cadence:            bd.getUint8(4),
      activityState:      bd.getUint8(5),
      uvRisk:             bd.getUint16(6, Endian.little) / 32767.0,
      blueLightIntensity: bd.getUint8(8),
      blueLightRatio:     bd.getUint16(10, Endian.little) / 32767.0, 
      colorTemp:          bd.getUint16(12, Endian.little), 
      clearChannel:       bd.getUint16(14, Endian.little), 
      noiseDbSpl:         bd.getUint8(17), // uint8_t (Unsigned)
    );

    noiseDbfs  = bd.getInt8(16).toDouble();
    noiseDbSpl = payload[17].toDouble();

    unawaited(_sessionDao.insertUnified(row));
    
    _latestTelemetry = row;
    _updateFitnessMetrics(row);
    _updateLightMetrics(row, ts);
    
    // Process rolling historical entries for dev oscilloscope
    _pushToDevHistory(row);

    notifyListeners();
  }

  // ─── Fitness metric derivation ───────────────────────────────────────────────

  void _updateFitnessMetrics(UnifiedTelemetry r) {
    _currentSteps   = r.stepCount;
    _currentCadence = r.cadence;
    _activityState  = r.activityState;

    final heightCm = _currentUser?.heightCm ?? 170.0;
    _distanceKm = (_currentSteps * heightCm * 0.414) / 100000.0;

    final weightKg = _currentUser?.weightKg ?? 70.0;
    final met = switch (_activityState) {
      2 => 5.0,  
      1 => 3.5,  
      _ => 0.0,  
    };
    _totalKcal += (met * 3.5 * weightKg) / 12000.0;
  }

  // ─── Light / photobiology metric derivation ──────────────────────────────────

  void _updateLightMetrics(UnifiedTelemetry r, DateTime ts) {
    _currentBlueRatio    = r.blueLightRatio;
    _colorTemp           = r.colorTemp.toInt();
    clearChannel         = r.clearChannel.toDouble();
    _currentUvIndex      = r.uvRisk * 11.0;

    if (r.clearChannel > 500 && r.colorTemp > 4500) {
      _sunlightSeconds++;
    }

    if (_currentUvIndex > 7.0 && _sunlightSeconds > 600) {
      _skinBurnRisk = 'High';
    } else if (_currentUvIndex > 4.0 && _sunlightSeconds > 1200) {
      _skinBurnRisk = 'Moderate';
    } else {
      _skinBurnRisk = 'Low';
    }

    if (ts.hour >= 19 && r.blueLightRatio > 0.35) {
      _nightBlueLightSeconds++;
      if (_nightBlueLightSeconds % 300 == 0 && _circadianScore > 0) {
        _circadianScore -= 1;
      }
    }
  }

  // ─── Dev Rolling History Management ──────────────────────────────────────────

  void _pushToDevHistory(UnifiedTelemetry r) {
    // Keep internal memory bounded to prevent memory leaks over long sessions
    if (_stepsHistory.length >= _maxBufferSize) {
      _stepsHistory.removeAt(0);
      _cadenceHistory.removeAt(0);
      _activityHistory.removeAt(0);
      _uvHistory.removeAt(0);
      _blueIntensityHistory.removeAt(0);
      _blueRatioHistory.removeAt(0);
      _colorTempHistory.removeAt(0);
      _clearChannelHistory.removeAt(0);
      _noiseDbSplHistory.removeAt(0);
    }

    // Append standard double telemetry data types
    _stepsHistory.add(r.stepCount.toDouble());
    _cadenceHistory.add(r.cadence.toDouble());
    _activityHistory.add(r.activityState.toDouble());
    _uvHistory.add(r.uvRisk * 11.0); // Converted to direct UV Index
    _blueIntensityHistory.add(r.blueLightIntensity.toDouble());
    _blueRatioHistory.add(r.blueLightRatio);
    _colorTempHistory.add(r.colorTemp.toDouble());
    _clearChannelHistory.add(r.clearChannel.toDouble());
    _noiseDbSplHistory.add(r.noiseDbSpl); // Add mic data to history
  }
}

void unawaited(Future<void> future) {
  future.catchError((e) => debugPrint('SessionStore unawaited error: $e'));
}