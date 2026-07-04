import 'dart:typed_data';

// ============================================================================
//  Live-mode BLE packet models
//
//  These structs mirror the unified 20-byte packed C struct.
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
// Light exposure class — 0=Dark, 1=Dim, 2=Moderate, 3=Bright, 4=Very Bright.
// ----------------------------------------------------------------------------
enum LightExposureClass {
  dark(0x00),
  dim(0x01),
  moderate(0x02),
  bright(0x03),
  veryBright(0x04);

  final int value;
  const LightExposureClass(this.value);

  static LightExposureClass fromByte(int b) {
    for (final c in LightExposureClass.values) {
      if (c.value == b) return c;
    }
    return LightExposureClass.dark;
  }

  String get label => switch (this) {
    LightExposureClass.dark       => 'Dark',
    LightExposureClass.dim        => 'Dim',
    LightExposureClass.moderate   => 'Moderate',
    LightExposureClass.bright     => 'Bright',
    LightExposureClass.veryBright => 'Very Bright',
  };
}

// ----------------------------------------------------------------------------
// Audio environment class
// 1=Very Quiet, 2=Quiet, 3=Moderate, 4=Lively, 5=Noisy, 6=Very Noisy, 7=High Exp
// ----------------------------------------------------------------------------
enum AudioEnvClass {
  veryQuiet(0x01),
  quiet(0x02),
  moderate(0x03),
  lively(0x04),
  noisy(0x05),
  veryNoisy(0x06),
  highExposure(0x07),
  unavailable(0xFF);

  final int value;
  const AudioEnvClass(this.value);

  static AudioEnvClass fromByte(int b) {
    for (final c in AudioEnvClass.values) {
      if (c.value == b) return c;
    }
    return AudioEnvClass.unavailable;
  }

  String get label => switch (this) {
    AudioEnvClass.veryQuiet    => 'Very Quiet',
    AudioEnvClass.quiet        => 'Quiet',
    AudioEnvClass.moderate     => 'Moderate',
    AudioEnvClass.lively       => 'Lively',
    AudioEnvClass.noisy        => 'Noisy',
    AudioEnvClass.veryNoisy    => 'Very Noisy',
    AudioEnvClass.highExposure => 'High Exposure',
    AudioEnvClass.unavailable  => 'Unavailable',
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
//  Unified Metrics packet  — 20 bytes
//
//  | 0       | msg_type       = 0x55                   |
//  | 2-3 LE  | step_count     uint16                   |
//  | 4       | light_class    uint8                    |
//  | 5-6 LE  | blue_clear     uint16                   |
//  | 9-10 LE | laeq_x10       uint16                   |
//  | 11      | audio_class    uint8                    |
// ============================================================================
class UnifiedLivePacket {
  final int?               id;
  final int                sessionId;
  final int                tsMs;
  final int                stepCount;
  final LightExposureClass lightClass;
  final int                blueClearRatio;
  final int                laeqX10;
  final AudioEnvClass      audioClass;

  const UnifiedLivePacket({
    this.id,
    required this.sessionId,
    required this.tsMs,
    required this.stepCount,
    required this.lightClass,
    required this.blueClearRatio,
    required this.laeqX10,
    required this.audioClass,
  });

  double get laeqDb => laeqX10 / 10.0;
  double get actualRatio => blueClearRatio / 10000.0;

  // ── Canonical parser ────────────────────────────────────────────────────────
  static UnifiedLivePacket fromBytes(
    List<int> bytes, {
    required int sessionId,
    required int tsMs,
  }) {
    assert(bytes.length >= 20, 'UnifiedLivePacket expects 20 bytes, got ${bytes.length}');
    final bd = ByteData.sublistView(Uint8List.fromList(bytes));
    
    return UnifiedLivePacket(
      sessionId:      sessionId,
      tsMs:           tsMs,
      stepCount:      bd.getUint16(2, Endian.little),
      lightClass:     LightExposureClass.fromByte(bytes[4]),
      blueClearRatio: bd.getUint16(5, Endian.little),
      laeqX10:        bd.getUint16(9, Endian.little),
      audioClass:     AudioEnvClass.fromByte(bytes[11]),
    );
  }

  // ── SQLite persistence ──────────────────────────────────────────────────────
  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'session_id':       sessionId,
    'ts_ms':            tsMs,
    'step_count':       stepCount,
    'light_class':      lightClass.value,
    'blue_clear_ratio': blueClearRatio,
    'laeq_x10':         laeqX10,
    'audio_class':      audioClass.value,
  };

  factory UnifiedLivePacket.fromMap(Map<String, dynamic> m) => UnifiedLivePacket(
    id:             m['id']               as int?,
    sessionId:      m['session_id']       as int,
    tsMs:           m['ts_ms']            as int,
    stepCount:      m['step_count']       as int,
    lightClass:     LightExposureClass.fromByte(m['light_class'] as int),
    blueClearRatio: m['blue_clear_ratio'] as int,
    laeqX10:        m['laeq_x10']         as int,
    audioClass:     AudioEnvClass.fromByte(m['audio_class'] as int),
  );
}
