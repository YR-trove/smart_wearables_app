/// Represents a single 1 Hz unified telemetry snapshot from the MCU.
class UnifiedTelemetry {
  final int?   id;
  final int    sessionId;
  final int    tsMs;

  // --- Kinematics ---
  final int    stepCount;
  final int    cadence;
  final int    activityState;

  // --- Spectral light ---
  final double uvRisk;
  final int    blueLightIntensity;
  final double blueLightRatio;
  
  final int    colorTemp; 
  
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
    sessionId:          m['session_id']          as int,
    tsMs:               m['ts_ms']               as int,
    stepCount:          m['step_count']          as int,
    cadence:            m['cadence']             as int,
    activityState:      m['activity_state']      as int,
    uvRisk:             (m['uv_risk']            as num).toDouble(),
    blueLightIntensity: m['blue_light_intensity']  as int,
    blueLightRatio:     (m['blue_light_ratio']     as num).toDouble(),
    
    
    colorTemp:          (m['color_temp']           as num).toInt(), 
    
    clearChannel:       m['clear_channel']         as int,

    noiseDbSpl:
  );

  String get activityLabel => switch (activityState) {
    0 => 'Idle',
    1 => 'Walking',
    2 => 'Running',
    _ => 'Unknown',
  };
}