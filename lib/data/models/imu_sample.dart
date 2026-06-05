/// One IMU packet decoded from the BLE 20-byte frame (type 'A' or 'G').
class ImuSample {
  final int timestampMs;  // DateTime.now().millisecondsSinceEpoch
  final int stepCount;    // cumulative steps sent by mainboard
  final double metric3;   // reserved — not yet defined by firmware

  const ImuSample({
    required this.timestampMs,
    required this.stepCount,
    required this.metric3,
  });

  Map<String, dynamic> toMap(int sessionId) => {
    'session_id': sessionId,
    'ts_ms': timestampMs,
    'step_count': stepCount,
    'metric3': metric3,
  };
}
