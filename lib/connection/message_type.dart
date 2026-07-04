/// BLE Live-mode message type identifiers.
///
/// These match the BLE_MSG_* constants in ble_live_payload.h on the mainboard.
/// The old unifiedState(0x55) frame is no longer sent during ble_live workflow;
/// the board now sends three independent fixed-size packets.
enum MsgType {
  // ── Live-mode packets (ble_live workflow) ─────────────────────────────────

  /// 20-byte unified metrics packet. Sent every 500 ms unconditionally (2 Hz).
  /// Parse with [UnifiedLivePacket.fromBytes].
  unifiedMetrics(0x55),

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
