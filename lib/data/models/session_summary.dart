/// Aggregated metrics for a completed (or checkpointed) session.
/// Written to `session_summary` on endSession() and every 30 s checkpoint.
class SessionSummary {
  final int sessionId;
  final int totalSteps;
  final double peakNoiseDb;
  final double noiseDosePct;      // 0.0–1.0 (WHO 85 dB / 8 h limit)
  final double noiseExposureSec;
  final double blueLightDose;     // integrated intensity over session
  final double avgUvRisk;
  final double avgcolorTemp;        // average color temperature (K)

  const SessionSummary({
    required this.sessionId,
    required this.totalSteps,
    required this.peakNoiseDb,
    required this.noiseDosePct,
    required this.noiseExposureSec,
    required this.blueLightDose,
    required this.avgUvRisk,
    required this.avgcolorTemp,
  });

  Map<String, dynamic> toMap() => {
    'session_id': sessionId,
    'total_steps': totalSteps,
    'peak_noise_db': peakNoiseDb,
    'noise_dose_pct': noiseDosePct,
    'noise_exposure_s': noiseExposureSec,
    'bluelight_dose': blueLightDose,
    'avg_uv_risk': avgUvRisk,
    'avg_color_temp': avgcolorTemp,
  };

  factory SessionSummary.fromMap(Map<String, dynamic> m) => SessionSummary(
    sessionId: m['session_id'] as int,
    
    totalSteps:       (m['total_steps']      as num?)?.toInt()    ?? 0,
    peakNoiseDb:      (m['peak_noise_db']    as num?)?.toDouble() ?? 0.0,
    noiseDosePct:     (m['noise_dose_pct']   as num?)?.toDouble() ?? 0.0,
    noiseExposureSec: (m['noise_exposure_s'] as num?)?.toDouble() ?? 0.0,
    blueLightDose:    (m['bluelight_dose']   as num?)?.toDouble() ?? 0.0,
    avgUvRisk:        (m['avg_uv_risk']      as num?)?.toDouble() ?? 0.0,
    avgcolorTemp:     (m['avg_color_temp']   as num?)?.toDouble() ?? 0.0,
  );
}