import 'package:flutter/foundation.dart';

class SensorBuffer extends ChangeNotifier {
  // Number of points visible on the screen
  static const int _maxPoints = 150;

  // --- Metrics Mode Buffers (0x55) ---
  final List<double> stepCountHistory    = [];
  final List<double> cadenceHistory      = [];
  final List<double> activityHistory     = [];
  final List<double> luxHistory          = [];
  final List<double> uvRiskHistory       = [];
  final List<double> blueIntensityHistory = [];
  final List<double> blueRatioHistory    = [];
  final List<double> colorTempHistory    = [];

  // --- Raw IMU Buffers (0x77) ---
  final List<double> accelX = [], accelY = [], accelZ = [];
  final List<double> gyroX  = [], gyroY  = [], gyroZ  = [];

  // --- Raw Spectral & Mic Buffers (0x77) ---
  final List<double> f3 = [], rawClear = [];
  final List<double> noiseDbSpl = [];
  final List<double> noiseDbfs  = [];

  void addMetrics({
    required double steps, required double cadence, required double activity,
    required double lux,   required double uvRisk,  required double blueIntensity,
    required double blueRatio, required double colorTemp,
  }) {
    _append(stepCountHistory,     steps);
    _append(cadenceHistory,       cadence);
    _append(activityHistory,      activity);
    _append(luxHistory,           lux);
    _append(uvRiskHistory,        uvRisk);
    _append(blueIntensityHistory, blueIntensity);
    _append(blueRatioHistory,     blueRatio);
    _append(colorTempHistory,     colorTemp);
    notifyListeners();
  }

  void addRawAccel(double x, double y, double z) {
    _append(accelX, x); _append(accelY, y); _append(accelZ, z);
    notifyListeners();
  }

  void addRawGyro(double x, double y, double z) {
    _append(gyroX, x); _append(gyroY, y); _append(gyroZ, z);
    notifyListeners();
  }

  void addRawLight(double clearVal, double f3val) {
    _append(rawClear, clearVal); _append(f3, f3val);
    notifyListeners();
  }

  /// Receives raw BLE integer values and stores them in the double buffers.
  /// [dbSpl] — uint8 dB SPL  (0‥255), as delivered by frame[N] (int).
  /// [dbFs]  — int8  dBFS   (-128‥127), as delivered by bd.getInt8(N) (int).
  void addRawMic(int dbSpl, int dbFs) {
    _append(noiseDbSpl, dbSpl.toDouble());
    _append(noiseDbfs,  dbFs.toDouble());
    notifyListeners();
  }

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
    stepCountHistory.clear(); cadenceHistory.clear(); activityHistory.clear();
    luxHistory.clear(); uvRiskHistory.clear(); blueIntensityHistory.clear();
    blueRatioHistory.clear(); colorTempHistory.clear();

    accelX.clear(); accelY.clear(); accelZ.clear();
    gyroX.clear();  gyroY.clear();  gyroZ.clear();
    f3.clear(); rawClear.clear();
    noiseDbSpl.clear(); noiseDbfs.clear();

    notifyListeners();
  }
}
