/// Represents a single 1 Hz unified telemetry snapshot from the MCU.
///
/// All IMU math (step counting, cadence, activity classification) and
/// AS7341 spectral light processing are performed on-device. This model
/// holds the already-fused values exactly as decoded from the 0x55 BLE packet.
class UnifiedTelemetry {
  final int?   id;
  final int    sessionId;
  final int    tsMs;

  // --- Kinematics (from LSM6DSO16IS, fused on MCU) ---
  /// Cumulative step count since device power-on.
  final int    stepCount;
  /// Current cadence in steps-per-minute. Zeroed after 2 s of rest.
  final int    cadence;
  /// Activity classification: 0 = Idle, 1 = Walking, 2 = Running.
  final int    activityState;

  // --- Spectral light (from AS7341, fused on MCU) ---
  /// UV exposure risk, Q15 → float in [0.0, 1.0].
  final double uvRisk;
  /// Raw integrated blue-light power (AS7341 channel).
  final int    blueLightIntensity;
  /// Blue light fraction of total spectrum, Q15 → float in [0.0, 1.0].
  final double blueLightRatio;
  /// Indoor/outdoor light quality index, Q15 → float in [0.0, 1.0].
  final double colorTemp;
  /// AS7341 Clear channel — overall illuminance proxy (raw counts).
  final int    clearChannel;

  const UnifiedTelemetry({
    this.id,
    required this.sessionId,
    required this.tsMs,
    required this.stepCount,
    required this.cadence,
    required this.activityState,
    required this.uvRisk,
    required this.blueLightIntensity,
    required this.blueLightRatio,
    required this.colorTemp,
    required this.clearChannel,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'session_id':           sessionId,
    'ts_ms':                tsMs,
    'step_count':           stepCount,
    'cadence':              cadence,
    'activity_state':       activityState,
    'uv_risk':              uvRisk,
    'blue_light_intensity': blueLightIntensity,
    'blue_light_ratio':     blueLightRatio,
    'color_temp':           colorTemp,
    'clear_channel':        clearChannel,
  };

  factory UnifiedTelemetry.fromMap(Map<String, dynamic> m) => UnifiedTelemetry(
    id:                 m['id'] as int?,
    sessionId:          m['session_id']           as int,
    tsMs:               m['ts_ms']                as int,
    stepCount:          m['step_count']            as int,
    cadence:            m['cadence']               as int,
    activityState:      m['activity_state']        as int,
    uvRisk:             (m['uv_risk']              as num).toDouble(),
    blueLightIntensity: m['blue_light_intensity']  as int,
    blueLightRatio:     (m['blue_light_ratio']     as num).toDouble(),
    sunLikeIndex:       (m['sun_like_index']       as num).toDouble(),
    clearChannel:       m['clear_channel']         as int,
  );

  /// Human-readable activity label for the current [activityState].
  String get activityLabel => switch (activityState) {
    0 => 'Idle',
    1 => 'Walking',
    2 => 'Running',
    _ => 'Unknown',
  };
}
