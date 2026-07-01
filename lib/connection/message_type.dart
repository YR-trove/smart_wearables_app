/// BLE Live-mode message type identifiers.
///
/// These match the BLE_MSG_* constants in ble_live_payload.h on the mainboard.
/// The old unifiedState(0x55) frame is no longer sent during ble_live workflow;
/// the board now sends three independent fixed-size packets.
enum MsgType {
  // ── Live-mode packets (ble_live workflow) ─────────────────────────────────

  /// 7-byte IMU metrics packet. Sent every 1 s unconditionally.
  /// [BleLiveImuPacket.fromBytes]
  imuMetrics(0x50),

  /// 3-byte light metrics packet. Sent every 3 s on value change.
  /// [LiveLightPacket.fromBytes]
  lightMetrics(0x51),

  /// 4-byte mic / audio metrics packet. Sent every 3 s on value change.
  /// [LiveMicPacket.fromBytes]
  micMetrics(0x52),

  /// 2-byte connection-event packet (LIVE_START / LIVE_STOP).
  connectionEvent(0x53),

  // ── Legacy / sync packets (kept for BLE-sync workflow) ────────────────────

  /// TODO-REMOVE: Old 20-byte unified state frame (0x55). No longer sent
  /// during ble_live mode. Remove once BLE-sync workflow is also migrated.
  unifiedState(0x55),

  /// TODO-REMOVE: HAR packet — not yet implemented on mainboard side.
  har(0xe0),

  /// End-of-stream sentinel.
  end(0xff);

  final int description;
  const MsgType(this.description);

  /// Returns the [MsgType] matching [byteValue], or null if unknown.
  static MsgType? fromByte(int byteValue) {
    for (final t in MsgType.values) {
      if (t.description == byteValue) return t;
    }
    return null;
  }
}
