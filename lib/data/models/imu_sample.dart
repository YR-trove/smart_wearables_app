/// One IMU packet decoded from the BLE 20-byte frame (type 'A' or 'G').
class ImuSample {
  final int      sessionId;
  final DateTime timestamp;
  final String   type;        // 'A' = accelerometer, 'G' = gyroscope
  final double   x;
  final double   y;
  final double   z;
  final int?     stepCount;   // cumulative steps (accelerometer packets only)
  final double?  metric3;     // reserved — not yet defined by firmware

  const ImuSample({
    required this.sessionId,
    required this.timestamp,
    required this.type,
    required this.x,
    required this.y,
    required this.z,
    this.stepCount,
    this.metric3,
  });

  Map<String, dynamic> toMap(int sid) => {
    'session_id': sid,
    'ts_ms':      timestamp.millisecondsSinceEpoch,
    'step_count': stepCount ?? 0,
    'metric3':    metric3 ?? 0.0,
  };
}
