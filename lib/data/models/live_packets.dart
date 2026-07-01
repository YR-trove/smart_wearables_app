import 'dart:typed_data';

// ============================================================================
//  Live-mode BLE packet models
//
//  These three structs mirror the packed C structs in ble_live_payload.h.
//  Each fromBytes() is the single canonical parse point — no byte-offset
//  arithmetic anywhere else in the app.
// ============================================================================

// ----------------------------------------------------------------------------
// Activity enum — mirrors BleLiveActivityState in ble_live_payload.h
// ----------------------------------------------------------------------------
enum LiveActivityState {
  unknown(0x00),
  stationary(0x01),
  walking(0x02),
  running(0x03);

  final int value;
  const LiveActivityState(this.value);

  static LiveActivityState fromByte(int b) {
    for (final s in LiveActivityState.values) {
      if (s.value == b) return s;
    }
    return LiveActivityState.unknown;
  }

  String get label => switch (this) {
    LiveActivityState.unknown    => 'Unknown',
    LiveActivityState.stationary => 'Stationary',
    LiveActivityState.walking    => 'Walking',
    LiveActivityState.running    => 'Running',
  };
}

// ----------------------------------------------------------------------------
// Light exposure class — mirrors BleLiveLightExposureClass
// ----------------------------------------------------------------------------
enum LightExposureClass {
  dark(0x00),
  dim(0x01),
  indoor(0x02),
  bright(0x03),
  outdoor(0x04);

  final int value;
  const LightExposureClass(this.value);

  static LightExposureClass fromByte(int b) {
    for (final c in LightExposureClass.values) {
      if (c.value == b) return c;
    }
    return LightExposureClass.dark;
  }

  String get label => switch (this) {
    LightExposureClass.dark    => 'Dark',
    LightExposureClass.dim     => 'Dim',
    LightExposureClass.indoor  => 'Indoor',
    LightExposureClass.bright  => 'Bright',
    LightExposureClass.outdoor => 'Outdoor',
  };
}

// ----------------------------------------------------------------------------
// Audio environment class — mirrors BleLiveEnvClass
// ----------------------------------------------------------------------------
enum AudioEnvClass {
  quiet(0x00),
  moderate(0x01),
  loud(0x02),
  veryLoud(0x03);

  final int value;
  const AudioEnvClass(this.value);

  static AudioEnvClass fromByte(int b) {
    for (final c in AudioEnvClass.values) {
      if (c.value == b) return c;
    }
    return AudioEnvClass.quiet;
  }

  String get label => switch (this) {
    AudioEnvClass.quiet    => 'Quiet',
    AudioEnvClass.moderate => 'Moderate',
    AudioEnvClass.loud     => 'Loud',
    AudioEnvClass.veryLoud => 'Very Loud',
  };
}

// ----------------------------------------------------------------------------
// Connection-event enum — mirrors BleLiveConnectionEvent
// ----------------------------------------------------------------------------
enum LiveConnectionEvent {
  liveStart(0x01),
  liveStop(0x02);

  final int value;
  const LiveConnectionEvent(this.value);

  static LiveConnectionEvent? fromByte(int b) {
    for (final e in LiveConnectionEvent.values) {
      if (e.value == b) return e;
    }
    return null;
  }
}

// ============================================================================
//  IMU metrics packet  — 7 bytes
//
//  | 0       | msg_type       = 0x50                   |
//  | 1–4 LE  | step_count     uint32                   |
//  | 5       | activity_state uint8                    |
//  | 6       | reserved       0x00                     |
// ============================================================================
class LiveImuPacket {
  final int?             id;
  final int              sessionId;
  final int              tsMs;
  final int              stepCount;    // cumulative steps since LIVE_START
  final LiveActivityState activity;

  const LiveImuPacket({
    this.id,
    required this.sessionId,
    required this.tsMs,
    required this.stepCount,
    required this.activity,
  });

  // ── Canonical parser ────────────────────────────────────────────────────────
  static LiveImuPacket fromBytes(
    List<int> bytes, {
    required int sessionId,
    required int tsMs,
  }) {
    assert(bytes.length >= 7, 'LiveImuPacket expects 7 bytes, got ${bytes.length}');
    final bd = ByteData.sublistView(Uint8List.fromList(bytes));
    return LiveImuPacket(
      sessionId: sessionId,
      tsMs:      tsMs,
      stepCount: bd.getUint32(1, Endian.little),
      activity:  LiveActivityState.fromByte(bd.getUint8(5)),
    );
  }

  // ── SQLite persistence ──────────────────────────────────────────────────────
  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'session_id':     sessionId,
    'ts_ms':          tsMs,
    'step_count':     stepCount,
    'activity_state': activity.value,
  };

  factory LiveImuPacket.fromMap(Map<String, dynamic> m) => LiveImuPacket(
    id:        m['id']             as int?,
    sessionId: m['session_id']     as int,
    tsMs:      m['ts_ms']          as int,
    stepCount: m['step_count']     as int,
    activity:  LiveActivityState.fromByte(m['activity_state'] as int),
  );
}

// ============================================================================
//  Light metrics packet  — 3 bytes
//
//  | 0 | msg_type              = 0x51     |
//  | 1 | exposure_class        uint8      |
//  | 2 | light_color_intensity uint8 0–255|
// ============================================================================
class LiveLightPacket {
  final int?              id;
  final int               sessionId;
  final int               tsMs;
  final LightExposureClass exposureClass;
  final int               intensity;  // 0–255 normalised

  const LiveLightPacket({
    this.id,
    required this.sessionId,
    required this.tsMs,
    required this.exposureClass,
    required this.intensity,
  });

  static LiveLightPacket fromBytes(
    List<int> bytes, {
    required int sessionId,
    required int tsMs,
  }) {
    assert(bytes.length >= 3, 'LiveLightPacket expects 3 bytes, got ${bytes.length}');
    return LiveLightPacket(
      sessionId:     sessionId,
      tsMs:          tsMs,
      exposureClass: LightExposureClass.fromByte(bytes[1]),
      intensity:     bytes[2],
    );
  }

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'session_id':     sessionId,
    'ts_ms':          tsMs,
    'exposure_class': exposureClass.value,
    'intensity':      intensity,
  };

  factory LiveLightPacket.fromMap(Map<String, dynamic> m) => LiveLightPacket(
    id:            m['id']             as int?,
    sessionId:     m['session_id']     as int,
    tsMs:          m['ts_ms']          as int,
    exposureClass: LightExposureClass.fromByte(m['exposure_class'] as int),
    intensity:     m['intensity']      as int,
  );
}

// ============================================================================
//  Mic metrics packet  — 4 bytes
//
//  | 0     | msg_type          = 0x52              |
//  | 1     | environment_class uint8               |
//  | 2–3LE | laeq_x10          uint16  (/ 10.0 → dB)|
// ============================================================================
class LiveMicPacket {
  final int?          id;
  final int           sessionId;
  final int           tsMs;
  final AudioEnvClass envClass;
  final int           laeqX10;    // LAeq × 10  (e.g. 653 → 65.3 dB)

  const LiveMicPacket({
    this.id,
    required this.sessionId,
    required this.tsMs,
    required this.envClass,
    required this.laeqX10,
  });

  /// LAeq in dB as a double.
  double get laeqDb => laeqX10 / 10.0;

  static LiveMicPacket fromBytes(
    List<int> bytes, {
    required int sessionId,
    required int tsMs,
  }) {
    assert(bytes.length >= 4, 'LiveMicPacket expects 4 bytes, got ${bytes.length}');
    final bd = ByteData.sublistView(Uint8List.fromList(bytes));
    return LiveMicPacket(
      sessionId: sessionId,
      tsMs:      tsMs,
      envClass:  AudioEnvClass.fromByte(bytes[1]),
      laeqX10:   bd.getUint16(2, Endian.little),
    );
  }

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'session_id': sessionId,
    'ts_ms':      tsMs,
    'env_class':  envClass.value,
    'laeq_x10':   laeqX10,
  };

  factory LiveMicPacket.fromMap(Map<String, dynamic> m) => LiveMicPacket(
    id:        m['id']         as int?,
    sessionId: m['session_id'] as int,
    tsMs:      m['ts_ms']      as int,
    envClass:  AudioEnvClass.fromByte(m['env_class'] as int),
    laeqX10:   m['laeq_x10']  as int,
  );
}
