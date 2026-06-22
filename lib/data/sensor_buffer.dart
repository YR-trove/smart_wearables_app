import 'package:flutter/foundation.dart';

class SensorBuffer extends ChangeNotifier {
  // Number of points visible on the screen (~1.5 seconds at 100Hz)
  static const int _maxPoints = 150;

  // --- Metrics Mode Buffers ---
  final List<double> stepCountHistory = [];       // NEW
  final List<double> cadenceHistory = [];
  final List<double> activityHistory = [];        // NEW
  final List<double> luxHistory = [];
  final List<double> uvRiskHistory = [];          // NEW
  final List<double> blueIntensityHistory = [];   // NEW
  final List<double> blueRatioHistory = [];
  final List<double> colorTempHistory = [];

  // --- Raw IMU Buffers ---
  final List<double> accelX = [], accelY = [], accelZ = [];
  final List<double> gyroX = [], gyroY = [], gyroZ = [];

  // --- Raw Spectral Buffers ---
  final List<double> f3 = [], rawClear = []; // For example, f3 = 3rd spectral channel, clear = ambient light
  final List<double> noiseDbSpl = [], noiseDbfs = []; // Microphone data: SPL and dBFS

  void addMetrics({
    required double steps,
    required double cadence,
    required double activity,
    required double lux,
    required double uvRisk,
    required double blueIntensity,
    required double blueRatio,
    required double colorTemp,
  }) {
    _append(stepCountHistory, steps);
    _append(cadenceHistory, cadence);
    _append(activityHistory, activity);
    _append(luxHistory, lux);
    _append(uvRiskHistory, uvRisk);
    _append(blueIntensityHistory, blueIntensity);
    _append(blueRatioHistory, blueRatio);
    _append(colorTempHistory, colorTemp);
    debugPrint('Buffer: Added new point. Total points: ${cadenceHistory.length}');
    notifyListeners(); // This is the trigger for the UI to redraw
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
    f3.add(f3val); rawClear.add(clearVal);
    _append(f3, f3val);
    _append(rawClear, clearVal);
    notifyListeners();
  }
  void addRawMic(double dbSpl, double dbFs) {
    noiseDbSpl.add(dbSpl); noiseDbfs.add(dbFs);
    _append(noiseDbSpl, dbSpl);
    _append(noiseDbfs, dbFs);
    notifyListeners();
  }
  void _append(List<double> list, double value) {
    list.add(value);
    if (list.length > _maxPoints) list.removeAt(0);
  }

  void clear() {
    stepCountHistory.clear();
    cadenceHistory.clear();
    activityHistory.clear();
    luxHistory.clear();
    uvRiskHistory.clear();
    blueIntensityHistory.clear();
    blueRatioHistory.clear();
    colorTempHistory.clear();
    
    accelX.clear(); accelY.clear(); accelZ.clear();
    gyroX.clear(); gyroY.clear(); gyroZ.clear();
    f3.clear(); rawClear.clear();
    noiseDbSpl.clear(); noiseDbfs.clear();

    notifyListeners();
  }
}