import 'package:flutter/foundation.dart';

/// In-memory rolling buffer for the dev-dashboard charts.
/// Each list holds up to [_maxPoints] samples; oldest is dropped when full.
class SensorBuffer extends ChangeNotifier {
  static const int _maxPoints = 150;

  // ── Live IMU (0x50) ────────────────────────────────────────────────────────
  final List<double> stepCountHistory = [];
  final List<double> activityHistory  = [];

  // ── Live Light (0x51) ─────────────────────────────────────────────────────
  final List<double> intensityHistory  = [];
  final List<double> exposureHistory   = []; // exposure_class integer value

  // ── Live Mic (0x52) ───────────────────────────────────────────────────────
  final List<double> laeqHistory    = [];   // LAeq in dB (laeqX10 / 10.0)
  final List<double> envClassHistory = [];  // env_class integer value

  // ── TODO-REMOVE: Legacy buffers from old unified-telemetry / 0x77 raw mode ─
  // These fields are no longer populated by any live-mode packet.
  // Remove once dev-dashboard widgets are updated.
  final List<double> cadenceHistory       = []; // TODO-REMOVE
  final List<double> luxHistory           = []; // TODO-REMOVE
  final List<double> uvRiskHistory        = []; // TODO-REMOVE
  final List<double> blueIntensityHistory = []; // TODO-REMOVE
  final List<double> blueRatioHistory     = []; // TODO-REMOVE
  final List<double> colorTempHistory     = []; // TODO-REMOVE

  // ── TODO-REMOVE: Raw IMU / spectral / mic buffers (0x77 dev-mode) ─────────
  final List<double> accelX = [], accelY = [], accelZ = []; // TODO-REMOVE
  final List<double> gyroX  = [], gyroY  = [], gyroZ  = []; // TODO-REMOVE
  final List<double> f3 = [], rawClear = [];                 // TODO-REMOVE
  final List<double> noiseDbSpl = [];                        // TODO-REMOVE
  final List<double> noiseDbfs  = [];                        // TODO-REMOVE

  // ── Live-mode add methods ──────────────────────────────────────────────────

  /// Called on every 0x50 IMU metrics packet (~1 Hz).
  void addImuMetrics({required double steps, required double activity}) {
    _append(stepCountHistory, steps);
    _append(activityHistory,  activity);
    notifyListeners();
  }

  /// Called on every 0x51 light metrics packet (~3 s, change-gated).
  void addLightMetrics({required double intensity, required double exposureClass}) {
    _append(intensityHistory, intensity);
    _append(exposureHistory,  exposureClass);
    notifyListeners();
  }

  /// Called on every 0x52 mic metrics packet (~3 s, change-gated).
  /// [laeqDb] — LAeq in dB (= laeqX10 / 10.0).
  void addMicMetrics({required double laeqDb, required double envClass}) {
    _append(laeqHistory,     laeqDb);
    _append(envClassHistory, envClass);
    notifyListeners();
  }

  // ── TODO-REMOVE: Legacy add methods ───────────────────────────────────────
  // These are no-ops kept to avoid compile errors while callers are updated.

  /// TODO-REMOVE: addMetrics was the old unified-packet update.
  /// Replace all callers with addImuMetrics / addLightMetrics / addMicMetrics.
  void addMetrics({ // TODO-REMOVE
    required double steps,    required double cadence,
    required double activity, required double lux,
    required double uvRisk,   required double blueIntensity,
    required double blueRatio, required double colorTemp,
  }) { // TODO-REMOVE
    // Intentional no-op — fields no longer exist in live-mode packets.
    debugPrint('SensorBuffer.addMetrics: deprecated, use per-packet methods'); // TODO-REMOVE
  } // TODO-REMOVE

  /// TODO-REMOVE: Raw 0x77 dev-mode add methods — no equivalent in ble_live.
  void addRawAccel(double x, double y, double z) {} // TODO-REMOVE
  void addRawGyro(double x, double y, double z)  {} // TODO-REMOVE
  void addRawLight(double clearVal, double f3val) {} // TODO-REMOVE
  void addRawMic(int dbSpl, int dbFs)             {} // TODO-REMOVE

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _append(List<double> list, double value) {
    list.add(value);
    if (list.length > _maxPoints) list.removeAt(0);
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }

  void clear() {
    stepCountHistory.clear(); activityHistory.clear();
    intensityHistory.clear(); exposureHistory.clear();
    laeqHistory.clear();      envClassHistory.clear();
    // TODO-REMOVE: clear legacy buffers below once removed
    cadenceHistory.clear();       // TODO-REMOVE
    luxHistory.clear();           // TODO-REMOVE
    uvRiskHistory.clear();        // TODO-REMOVE
    blueIntensityHistory.clear(); // TODO-REMOVE
    blueRatioHistory.clear();     // TODO-REMOVE
    colorTempHistory.clear();     // TODO-REMOVE
    accelX.clear(); accelY.clear(); accelZ.clear(); // TODO-REMOVE
    gyroX.clear();  gyroY.clear();  gyroZ.clear();  // TODO-REMOVE
    f3.clear(); rawClear.clear();                   // TODO-REMOVE
    noiseDbSpl.clear(); noiseDbfs.clear();          // TODO-REMOVE
    notifyListeners();
  }
}
