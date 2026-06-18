import 'dart:async';
import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// UserProfile — lightweight value object injected into SessionStore
// ---------------------------------------------------------------------------
class UserProfile {
  final double heightCm;
  final double weightKg;

  const UserProfile({required this.heightCm, required this.weightKg});
}

// ---------------------------------------------------------------------------
// SessionStore — ChangeNotifier that owns ALL computed BLE-derived state.
//
// Wire-up:
//   1. Create one instance and provide it above MaterialApp via
//      ChangeNotifierProvider<SessionStore>.
//   2. Call store.startSession(profile) when the user begins a session.
//   3. Feed every unified telemetry packet to store.onUnifiedPacket(packet).
//   4. Call store.endSession() on disconnect.
//
// The Fitness and Light pages read computed fields passively with
// context.watch<SessionStore>() — they never call notifyListeners().
// ---------------------------------------------------------------------------
class SessionStore extends ChangeNotifier {
  // ── User Profile ──────────────────────────────────────────────────────────
  UserProfile _profile = const UserProfile(heightCm: 170.0, weightKg: 70.0);
  UserProfile get userProfile => _profile;

  // ── Session clock ─────────────────────────────────────────────────────────
  DateTime? _sessionStartTime;
  DateTime? get sessionStartTime => _sessionStartTime;
  bool get isSessionActive => _sessionStartTime != null;

  Duration get elapsed =>
      _sessionStartTime == null
          ? Duration.zero
          : DateTime.now().difference(_sessionStartTime!);

  // ── Fitness metrics ───────────────────────────────────────────────────────
  int _currentSteps = 0;
  int get currentSteps => _currentSteps;

  double _distanceKm = 0.0;
  double get distanceKm => _distanceKm;

  double _totalKcal = 0.0;
  double get totalKcal => _totalKcal;

  /// 0 = Idle, 1 = Walking, 2 = Running
  int _activityState = 0;
  int get activityState => _activityState;

  // ── Light / Photobiology metrics ──────────────────────────────────────────
  int _sunlightSeconds = 0;
  int get sunlightSeconds => _sunlightSeconds;

  double _currentUvIndex = 0.0;
  double get currentUvIndex => _currentUvIndex;

  String _skinBurnRisk = 'Low';
  String get skinBurnRisk => _skinBurnRisk;

  int _nightBlueLightSeconds = 0;
  int get nightBlueLightSeconds => _nightBlueLightSeconds;

  /// Starts at 100 each morning; decremented by night-time blue-light exposure.
  int _circadianScore = 100;
  int get circadianScore => _circadianScore;

  /// Convenience label derived from _nightBlueLightSeconds.
  String get blueLightExposureLevel {
    if (_nightBlueLightSeconds < 1800) return 'Low';
    if (_nightBlueLightSeconds < 3600) return 'Moderate';
    return 'High';
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Call when a new session begins (user presses Start or device connects).
  void startSession(UserProfile profile) {
    _profile = profile;
    _sessionStartTime = DateTime.now();
    _resetFitness();
    _resetLight();
    notifyListeners();
  }

  /// Call on device disconnect or manual session stop.
  void endSession() {
    _sessionStartTime = null;
    notifyListeners();
  }

  /// Reset circadian score at midnight (call from a daily timer if desired).
  void resetDailyCircadian() {
    _circadianScore = 100;
    _nightBlueLightSeconds = 0;
    notifyListeners();
  }

  /// Main entry point — called once per BLE telemetry packet (1 Hz).
  ///
  /// Expected keys in [packet]:
  ///   Fitness : 'stepCount' (int), 'activityState' (int 0/1/2)
  ///   Light   : 'blueRatio' (double 0–1), 'sunLike' (double 0–1),
  ///             'uvRisk' (double 0–1)
  void onUnifiedPacket(Map<String, dynamic> packet) {
    _processFitnessMetrics(packet);
    _processLightMetrics(packet);
    notifyListeners();
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  void _processFitnessMetrics(Map<String, dynamic> packet) {
    _currentSteps = (packet['stepCount'] as num?)?.toInt() ?? _currentSteps;
    _activityState = (packet['activityState'] as num?)?.toInt() ?? _activityState;

    // Distance: stride length ≈ 41.4 % of body height
    _distanceKm =
        (_currentSteps * _profile.heightCm * 0.414) / 100000.0;

    // Calories: MET-based incremental accumulation (1 packet = 1 second)
    // Formula: Kcal/s = (MET × 3.5 × weightKg) / (200 × 60)
    final double met = _activityState == 2
        ? 8.0
        : _activityState == 1
            ? 3.5
            : 1.0;
    _totalKcal += (met * 3.5 * _profile.weightKg) / 12000.0;
  }

  void _processLightMetrics(Map<String, dynamic> packet) {
    final int currentHour = DateTime.now().hour;
    final double blueRatio =
        (packet['blueRatio'] as num?)?.toDouble() ?? 0.0;
    final double sunLike =
        (packet['sunLike'] as num?)?.toDouble() ?? 0.0;
    final double uvRiskNorm =
        (packet['uvRisk'] as num?)?.toDouble() ?? 0.0;

    // ── Sunlight accumulation ──
    if (sunLike > 0.8) {
      _sunlightSeconds++;
      _currentUvIndex = uvRiskNorm * 10.0; // normalised [0-1] → UV index [0-10]

      if (_currentUvIndex > 7.0 && _sunlightSeconds > 1200) {
        _skinBurnRisk = 'High';
      } else if (_currentUvIndex > 4.0 && _sunlightSeconds > 2400) {
        _skinBurnRisk = 'Moderate';
      } else {
        _skinBurnRisk = 'Low';
      }
    }

    // ── Night-time blue-light accumulation (after 19:00) ──
    if (currentHour >= 19 && blueRatio > 0.35) {
      _nightBlueLightSeconds++;

      // Deduct 1 circadian point for every 5 minutes of exposure
      if (_nightBlueLightSeconds % 300 == 0 && _circadianScore > 0) {
        _circadianScore--;
      }
    }
  }

  void _resetFitness() {
    _currentSteps = 0;
    _distanceKm = 0.0;
    _totalKcal = 0.0;
    _activityState = 0;
  }

  void _resetLight() {
    _sunlightSeconds = 0;
    _currentUvIndex = 0.0;
    _skinBurnRisk = 'Low';
    // Night blue-light and circadian score are day-level, not session-level;
    // they are only reset by resetDailyCircadian().
  }
}
