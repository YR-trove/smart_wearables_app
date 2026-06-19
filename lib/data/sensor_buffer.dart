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
  final List<double> sunLikeHistory = [];         // NEW

  // --- Raw IMU Buffers ---
  final List<double> accelX = [], accelY = [], accelZ = [];
  final List<double> gyroX = [], gyroY = [], gyroZ = [];

  // --- Raw Spectral Buffers ---
  final List<double> f1 = [], f2 = [], f3 = [], f4 = [];
  final List<double> f5 = [], f6 = [], f7 = [], f8 = [];

  void addMetrics({
    required double steps,
    required double cadence,
    required double activity,
    required double lux,
    required double uvRisk,
    required double blueIntensity,
    required double blueRatio,
    required double sunLike,
  }) {
    _append(stepCountHistory, steps);
    _append(cadenceHistory, cadence);
    _append(activityHistory, activity);
    _append(luxHistory, lux);
    _append(uvRiskHistory, uvRisk);
    _append(blueIntensityHistory, blueIntensity);
    _append(blueRatioHistory, blueRatio);
    _append(sunLikeHistory, sunLike);
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

  void addRawLight(double v1, double v2, double v3, double v4, double v5, double v6, double v7, double v8) {
    _append(f1, v1); _append(f2, v2); _append(f3, v3); _append(f4, v4);
    _append(f5, v5); _append(f6, v6); _append(f7, v7); _append(f8, v8);
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
    sunLikeHistory.clear();
    
    accelX.clear(); accelY.clear(); accelZ.clear();
    gyroX.clear(); gyroY.clear(); gyroZ.clear();
    f1.clear(); f2.clear(); f3.clear(); f4.clear();
    f5.clear(); f6.clear(); f7.clear(); f8.clear();
    
    notifyListeners();
  }
}