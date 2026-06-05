enum MsgType {
  /* --------------------------------- general -------------------------------- */
  battery(0xb0),
  notWorn(0xb1),
  calibration(0xb2),
  frameNotActive(0xb3),
  frameMoving(0xb4),
  /* ----------------------------------- imu ---------------------------------- */
  imuAccel(0x41), // ASCII 'A'
  imuGyro(0x47),  // ASCII 'G'
  /* ---------------------------------- light --------------------------------- */
  light(0x4C),    // ASCII 'L'
  /* ----------------------------------- mic ---------------------------------- */
  mic(0x4D),      // ASCII 'M'
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
