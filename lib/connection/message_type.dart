/// BLE Live-mode message type identifiers.
///
/// These match the BLE_MSG_* constants in ble_live_payload.h on the mainboard.
/// The old unifiedState(0x55) frame is no longer sent during ble_live workflow;
/// the board now sends three independent fixed-size packets.
enum MsgType {
  // ── Live-mode packets (ble_live workflow) ─────────────────────────────────

  /// 7-byte IMU metrics packet. Sent every 1 s unconditionally.
  /// Parse with [LiveImuPacket.fromBytes].
  imuMetrics(0x50),

  /// 3-byte light metrics packet. Sent every 3 s on value change.
  /// Parse with [LiveLightPacket.fromBytes].
  lightMetrics(0x51),

  /// 4-byte mic / audio metrics packet. Sent every 3 s on value change.
  /// Parse with [LiveMicPacket.fromBytes].
  micMetrics(0x52),

  /// 2-byte connection-event packet (LIVE_START / LIVE_STOP).
  connectionEvent(0x53),

  /// End-of-stream sentinel.
  end(0xff);

  /// The raw byte value that appears as the first byte of each packet.
  final int value;
  const MsgType(this.value);

  /// Returns the [MsgType] matching [byteValue], or null if unknown.
  static MsgType? fromByte(int byteValue) {
    for (final t in MsgType.values) {
      if (t.value == byteValue) return t;
    }
    return null;
  }
}
