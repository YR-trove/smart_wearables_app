/// One light-sensor packet decoded from the BLE 20-byte frame (type 'L').
class LightSample {
  final int      sessionId;
  final DateTime timestamp;
  final double   uvRisk;              // normalised UV risk index (0.0–1.0)
  final double   blueLightIntensity;  // raw intensity (lux or ADC units)
  final double   blueLightRatio;      // fraction of blue in total spectrum (0–1)
  final double   sunLikeIndex;        // circadian/sun-similarity score
  final double   metric1;             // reserved

  const LightSample({
    required this.sessionId,
    required this.timestamp,
    required this.uvRisk,
    required this.blueLightIntensity,
    required this.blueLightRatio,
    required this.sunLikeIndex,
    required this.metric1,
  });

  /// Maps to the shared sensor_snapshots table.
  /// f1=uvRisk, f2=blueLightIntensity, f3=blueLightRatio,
  /// f4=sunLikeIndex, f5=metric1
  Map<String, dynamic> toMap(int sid) => {
    'session_id': sid,
    'ts_ms':      timestamp.millisecondsSinceEpoch,
    'sensor_type': 'light',
    'f1': uvRisk,
    'f2': blueLightIntensity,
    'f3': blueLightRatio,
    'f4': sunLikeIndex,
    'f5': metric1,
  };
}
