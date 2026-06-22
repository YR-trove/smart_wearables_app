enum MsgType {
  /* ----------------------- unified telemetry frame ------------------------- */
  /// Single 20-byte state packet transmitted at 1 Hz by the MCU.
  /// Carries fused IMU kinematics + AS7341 spectral light metrics.
  unifiedState(0x55),
  /* ----------------------------------- har ---------------------------------- */
  har(0xe0),
  /* ----------------------------------- end ---------------------------------- */
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
