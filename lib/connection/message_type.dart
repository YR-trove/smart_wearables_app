enum MsgType {
  /* --------------------------------- general -------------------------------- */
  battery(0xb0),
  notWorn(0xb1),
  calibration(0xb2),
  frameNotActive(0xb3),
  frameMoving(0xb4),
  /* ----------------------- unified telemetry frame ------------------------- */
  /// Single 20-byte state packet transmitted at 1 Hz by the MCU.
  /// Carries fused IMU kinematics + AS7341 spectral light metrics.
  unifiedState(0x55),
  /* ----------------------------------- raw ---------------------------------- */
  accel(0x01),  // <-- ADDED FOR DEV MODE
  gyro(0x02),   // <-- ADDED FOR DEV MODE
  lightRawVis(0x03), // F1 through F8 <-- ADDED FOR DEV MODE
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
