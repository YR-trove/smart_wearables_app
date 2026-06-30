import 'dart:typed_data';

/// Represents a single 1 Hz unified telemetry snapshot from the MCU.
///
/// [fromFrame] is the single canonical byte-offset parse point for
/// the 20-byte `0x55` unified state BLE frame. All other code receives
/// a [UnifiedTelemetry] object — never raw bytes.
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

  // --- Audio ---
  final int    noiseDbSpl;  // uint8  — dB SPL (unsigned)
  final int    noiseDbFs;   // int8   — dBFS  (signed, stored as int)

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
    required this.noiseDbSpl,
    required this.noiseDbFs,
  });

  // ─── Canonical BLE frame parser ────────────────────────────────────────────
  // Single source of truth for all byte offsets in the 0x55 unified frame.
  // Layout (20 bytes):
  //   [0]      0x7B  start
  //   [1]      0x55  msg type
  //   [2–3]    stepCount      uint16 LE
  //   [4]      cadence        uint8
  //   [5]      activityState  uint8
  //   [6–7]    uvRisk         uint16 LE  (/ 32767.0)
  //   [8]      blueLightIntensity uint8
  //   [9]      reserved
  //   [10–11]  blueLightRatio  uint16 LE  (/ 32767.0)
  //   [12–13]  colorTemp       uint16 LE
  //   [14–15]  clearChannel    uint16 LE
  //   [16]     noiseDbFs       int8  (signed dBFS)
  //   [17]     noiseDbSpl      uint8 (unsigned dB SPL)
  //   [18]     reserved
  //   [19]     0x7D  end
  static UnifiedTelemetry fromFrame(
    List<int> frame, {
    required int sessionId,
    required int tsMs,
  }) {
    assert(frame.length == 20, 'fromFrame expects exactly 20 bytes');
    final bd = ByteData.sublistView(Uint8List.fromList(frame));
    return UnifiedTelemetry(
      sessionId:          sessionId,
      tsMs:               tsMs,
      stepCount:          bd.getUint16(2,  Endian.little),
      cadence:            bd.getUint8(4),
      activityState:      bd.getUint8(5),
      uvRisk:             bd.getUint16(6,  Endian.little) / 32767.0,
      blueLightIntensity: bd.getUint8(8),
      blueLightRatio:     bd.getUint16(10, Endian.little) / 32767.0,
      colorTemp:          bd.getUint16(12, Endian.little),
      clearChannel:       bd.getUint16(14, Endian.little),
      noiseDbFs:          bd.getInt8(16),
      noiseDbSpl:         bd.getUint8(17),
    );
  }

  // ─── Persistence ───────────────────────────────────────────────────────────

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
    'noise_db_spl':         noiseDbSpl,
    'noise_db_fs':          noiseDbFs,
  };

  factory UnifiedTelemetry.fromMap(Map<String, dynamic> m) => UnifiedTelemetry(
    id:                 m['id']                   as int?,
    sessionId:          m['session_id']           as int,
    tsMs:               m['ts_ms']                as int,
    stepCount:          m['step_count']           as int,
    cadence:            m['cadence']              as int,
    activityState:      m['activity_state']       as int,
    uvRisk:             (m['uv_risk']             as num).toDouble(),
    blueLightIntensity: m['blue_light_intensity'] as int,
    blueLightRatio:     (m['blue_light_ratio']    as num).toDouble(),
    colorTemp:          (m['color_temp']          as num).toInt(),
    clearChannel:       m['clear_channel']        as int,
    noiseDbSpl:         m['noise_db_spl']         as int,
    noiseDbFs:          m['noise_db_fs']          as int,
  );

  // ─── Helpers ───────────────────────────────────────────────────────────────

  String get activityLabel => switch (activityState) {
    0 => 'Idle',
    1 => 'Walking',
    2 => 'Running',
    _ => 'Unknown',
  };
}
