/// One microphone packet decoded from the BLE 20-byte frame (type 'M').
class MicSample {
  final int timestampMs;
  final double noiseLevel;  // sound pressure level in dB
  final double noiseTime;   // cumulative seconds above threshold
  final double metric2;     // reserved

  const MicSample({
    required this.timestampMs,
    required this.noiseLevel,
    required this.noiseTime,
    required this.metric2,
  });

  /// Maps to the shared sensor_snapshots table.
  /// f1=noiseLevel, f2=noiseTime, f3=metric2, f4=null, f5=null
  Map<String, dynamic> toMap(int sessionId) => {
    'session_id': sessionId,
    'ts_ms': timestampMs,
    'sensor_type': 'mic',
    'f1': noiseLevel,
    'f2': noiseTime,
    'f3': metric2,
    'f4': null,
    'f5': null,
  };
}
