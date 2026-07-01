import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:smart_wearables_app/data/database/session_dao.dart';
import 'package:smart_wearables_app/data/database/user_dao.dart';
import 'package:smart_wearables_app/data/models/live_packets.dart';
import 'package:smart_wearables_app/data/models/session_model.dart';
import 'package:smart_wearables_app/data/models/unified_telemetry.dart'; // TODO-REMOVE: delete when BLE-sync also migrated
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
  LiveImuPacket?   _latestImu;
  LiveLightPacket? _latestLight;
  LiveMicPacket?   _latestMic;

  /// TODO-REMOVE: latestTelemetry was the old unified-packet snapshot.
  /// Remove once BLE-sync workflow is migrated to live packets.
  UnifiedTelemetry? _latestTelemetry; // TODO-REMOVE
  UnifiedTelemetry? get latestTelemetry => _latestTelemetry; // TODO-REMOVE

  UserProfile?    get currentUser      => _currentUser;
  SessionModel?   get activeSession    => _activeSession;
  DateTime?       get sessionStartTime => _sessionStartTime;
  LiveImuPacket?   get latestImu       => _latestImu;
  LiveLightPacket? get latestLight     => _latestLight;
  LiveMicPacket?   get latestMic       => _latestMic;

  Duration get elapsed {
    if (_sessionStartTime == null) return Duration.zero;
    return DateTime.now().difference(_sessionStartTime!);
  }

  // ─── Fitness accumulators ──────────────────────────────────────────────────

  int    _currentSteps  = 0;
  int    _activityState = 0;   // 0=Unknown/Stationary, 1=Walking, 2=Running
  double _distanceKm    = 0.0;
  double _totalKcal     = 0.0;

  /// TODO-REMOVE: _currentCadence was derived from the old unified frame's
  /// cadence byte which no longer exists in the live-mode IMU packet.
  int _currentCadence = 0; // TODO-REMOVE

  int    get currentSteps   => _currentSteps;
  int    get currentCadence => _currentCadence; // TODO-REMOVE
  int    get activityState  => _activityState;
  double get distanceKm     => _distanceKm;
  double get totalKcal      => _totalKcal;

  String get activityLabel => switch (_activityState) {
    1 => 'Walking',
    2 => 'Running',
    _ => 'Stationary',
  };

  // ─── Audio ─────────────────────────────────────────────────────────────────

  double get latestLaeqDb     => _latestMic?.laeqDb             ?? 0.0;
  String get latestEnvLabel   => _latestMic?.envClass.label     ?? '—';

  /// TODO-REMOVE: noiseDbSpl / noiseDbFs were fields in the old unified frame.
  /// The new mic packet reports LAeq × 10 instead. Remove the getters below
  /// once all UI widgets are updated to use latestLaeqDb / latestEnvLabel.
  double get latestNoiseDbSpl => _latestMic?.laeqDb ?? 0.0; // TODO-REMOVE remapped
  double get latestNoiseDbFs  => 0.0;                       // TODO-REMOVE no equivalent

  // ─── Light / photobiology accumulators ────────────────────────────────────

  int    _sunlightSeconds       = 0;
  int    _nightBlueLightSeconds = 0;
  String _skinBurnRisk          = 'Low';
  int    _circadianScore        = 100;
  String _lightExposureLabel    = '—';
  int    _lightIntensity        = 0;   // 0–255

  /// TODO-REMOVE: _currentUvIndex, _currentBlueRatio, _colorTemp, _clearChannel
  /// were derived from the old AS7341 spectral fields in the unified frame.
  /// The live-mode light packet only carries exposure_class + intensity.
  /// Remove these fields and their getters once UI is updated.
  double _currentUvIndex   = 0.0; // TODO-REMOVE
  double _currentBlueRatio = 0.0; // TODO-REMOVE
  int    _colorTemp        = 0;   // TODO-REMOVE
  double _clearChannel     = 0.0; // TODO-REMOVE

  int    get sunlightSeconds       => _sunlightSeconds;
  int    get nightBlueLightSeconds => _nightBlueLightSeconds;
  String get skinBurnRisk          => _skinBurnRisk;
  int    get circadianScore        => _circadianScore;
  String get lightExposureLabel    => _lightExposureLabel;
  int    get lightIntensity        => _lightIntensity;
  double get currentUvIndex        => _currentUvIndex;   // TODO-REMOVE
  double get currentBlueRatio      => _currentBlueRatio; // TODO-REMOVE
  int    get colorTemp             => _colorTemp;        // TODO-REMOVE
  double get clearChannel          => _clearChannel;     // TODO-REMOVE

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

  /// TODO-REMOVE: The histories below map to fields that no longer exist in
  /// live-mode packets. Keep until dev-dashboard widgets are updated.
  final List<double> _cadenceHistory       = []; // TODO-REMOVE
  final List<double> _uvHistory            = []; // TODO-REMOVE
  final List<double> _blueIntensityHistory = []; // TODO-REMOVE
  final List<double> _blueRatioHistory     = []; // TODO-REMOVE
  final List<double> _colorTempHistory     = []; // TODO-REMOVE
  final List<double> _clearChannelHistory  = []; // TODO-REMOVE
  final List<double> _noiseDbSplHistory    = []; // TODO-REMOVE

  List<List<double>> get devMetricsHistory => [
    _stepsHistory,
    _activityHistory,
    _laeqHistory,
    _intensityHistory,
    // TODO-REMOVE: remove legacy lists below once dev-dashboard is updated
    _cadenceHistory,
    _uvHistory,
    _blueIntensityHistory,
    _blueRatioHistory,
    _colorTempHistory,
    _clearChannelHistory,
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
    _latestImu        = null;
    _latestLight      = null;
    _latestMic        = null;
    _latestTelemetry  = null; // TODO-REMOVE
    _sessionStartTime = null;
    _resetAccumulators();
    notifyListeners();
  }

  void _resetAccumulators() {
    _currentSteps   = 0;
    _currentCadence = 0; // TODO-REMOVE
    _activityState  = 0;
    _distanceKm     = 0.0;
    _totalKcal      = 0.0;

    _sunlightSeconds       = 0;
    _nightBlueLightSeconds = 0;
    _skinBurnRisk          = 'Low';
    _circadianScore        = 100;
    _lightExposureLabel    = '—';
    _lightIntensity        = 0;
    _currentUvIndex        = 0.0; // TODO-REMOVE
    _currentBlueRatio      = 0.0; // TODO-REMOVE
    _colorTemp             = 0;   // TODO-REMOVE
    _clearChannel          = 0.0; // TODO-REMOVE

    _stepsHistory.clear();
    _activityHistory.clear();
    _laeqHistory.clear();
    _intensityHistory.clear();
    _cadenceHistory.clear();       // TODO-REMOVE
    _uvHistory.clear();            // TODO-REMOVE
    _blueIntensityHistory.clear(); // TODO-REMOVE
    _blueRatioHistory.clear();     // TODO-REMOVE
    _colorTempHistory.clear();     // TODO-REMOVE
    _clearChannelHistory.clear();  // TODO-REMOVE
    _noiseDbSplHistory.clear();    // TODO-REMOVE
  }

  // ─── Live-mode packet handlers ────────────────────────────────────────────

  /// Called by MainShell on every 0x50 IMU metrics packet (1 Hz).
  Future<void> onImuPacket(LiveImuPacket packet) async {
    if (_activeSession == null) return;

    unawaited(_sessionDao.insertImu(packet));

    _latestImu     = packet;
    _currentSteps  = packet.stepCount;
    _activityState = packet.activity.value;

    final heightCm = _currentUser?.heightCm ?? 170.0;
    _distanceKm = (_currentSteps * heightCm * 0.414) / 100000.0;

    final weightKg = _currentUser?.weightKg ?? 70.0;
    final met = switch (_activityState) {
      2 => 5.0,
      1 => 3.5,
      _ => 0.0,
    };
    _totalKcal += (met * 3.5 * weightKg) / 12000.0;

    if (_stepsHistory.length >= _maxBufferSize) {
      _stepsHistory.removeAt(0);
      _activityHistory.removeAt(0);
    }
    _stepsHistory.add(packet.stepCount.toDouble());
    _activityHistory.add(packet.activity.value.toDouble());

    notifyListeners();
  }

  /// Called by MainShell on every 0x51 light metrics packet (3 Hz, change-gated).
  Future<void> onLightPacket(LiveLightPacket packet) async {
    if (_activeSession == null) return;

    unawaited(_sessionDao.insertLight(packet));

    _latestLight        = packet;
    _lightExposureLabel = packet.exposureClass.label;
    _lightIntensity     = packet.intensity;

    // Sunlight accumulation — use Outdoor/Bright class as proxy
    if (packet.exposureClass == LightExposureClass.outdoor ||
        packet.exposureClass == LightExposureClass.bright) {
      _sunlightSeconds += 3; // one env-epoch ≈ 3 s
    }

    // Night blue-light heuristic — Bright/Indoor after 19:00 risks circadian disruption.
    final hour = DateTime.now().hour;
    if (hour >= 19 &&
        (packet.exposureClass == LightExposureClass.indoor ||
         packet.exposureClass == LightExposureClass.bright)) {
      _nightBlueLightSeconds += 3;
      if (_nightBlueLightSeconds % 300 == 0 && _circadianScore > 0) {
        _circadianScore -= 1;
      }
    }

    if (_intensityHistory.length >= _maxBufferSize) _intensityHistory.removeAt(0);
    _intensityHistory.add(packet.intensity.toDouble());

    notifyListeners();
  }

  /// Called by MainShell on every 0x52 mic metrics packet (3 Hz, change-gated).
  Future<void> onMicPacket(LiveMicPacket packet) async {
    if (_activeSession == null) return;

    unawaited(_sessionDao.insertMic(packet));

    _latestMic = packet;

    if (_laeqHistory.length >= _maxBufferSize) _laeqHistory.removeAt(0);
    _laeqHistory.add(packet.laeqDb);

    notifyListeners();
  }

  /// Called by MainShell when a 0x53 connection-event packet arrives.
  /// Returns the ACK bytes to write back to the mainboard.
  List<int> onConnectionEvent(LiveConnectionEvent event) {
    debugPrint('SessionStore: connection event → ${event.name}');
    // ACK byte: single 0x06 (ASCII ACK)
    return const [0x06];
  }

  // ─── Legacy unified-packet handler ────────────────────────────────────────
  // TODO-REMOVE: Remove this method and all callers once BLE-sync workflow
  // is migrated to the live-packet protocol.

  Future<void> onUnifiedPacket(UnifiedTelemetry packet) async { // TODO-REMOVE
    if (_activeSession == null) return;
    unawaited(_sessionDao.insertUnified(packet));
    _latestTelemetry = packet;
    notifyListeners();
  }
}

void unawaited(Future<void> future) {
  future.catchError((e) => debugPrint('SessionStore unawaited error: $e'));
}
