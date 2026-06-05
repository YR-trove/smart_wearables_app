/// One microphone packet decoded from the BLE 20-byte frame (type 'M').
class MicSample {
  final int      sessionId;
  final DateTime timestamp;
  final double   noiseLevel;  // sound pressure level in dB
  final double   noiseTime;   // cumulative seconds above threshold
  final double   metric2;     // reserved

  const MicSample({
    required this.sessionId,
    required this.timestamp,
    required this.noiseLevel,
    required this.noiseTime,
    required this.metric2,
  });

  /// Maps to the shared sensor_snapshots table.
  /// f1=noiseLevel, f2=noiseTime, f3=metric2
  Map<String, dynamic> toMap(int sid) => {
    'session_id': sid,
    'ts_ms':      timestamp.millisecondsSinceEpoch,
    'sensor_type': 'mic',
    'f1': noiseLevel,
    'f2': noiseTime,
    'f3': metric2,
    'f4': null,
    'f5': null,
  };
}
