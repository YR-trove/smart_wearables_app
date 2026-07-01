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
    notifyListeners();
  }
}
