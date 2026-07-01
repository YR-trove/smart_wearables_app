import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// SQLite schema versions
/// v1 – initial (session_summary, sensor_snapshots, imu_data)
/// v2 – dropped above tables; added unified_telemetry
/// v3 – recreated unified_telemetry (DDL fix)
/// v4 – recreated unified_telemetry (noise_db_fs NOT NULL fix)
/// v5 – dropped unified_telemetry; added live_imu, live_light, live_mic
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'smart_wearables.db');
    return openDatabase(
      path,
      version: 5,
      onCreate:    _onCreate,
      onUpgrade:   _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Schema v5 — full creation (fresh install)
  // ---------------------------------------------------------------------------

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        name       TEXT    NOT NULL,
        age        INTEGER,
        weight_kg  REAL,
        height_cm  REAL,
        created_at TEXT    NOT NULL
      )''');

    await db.execute('''
      CREATE TABLE sessions (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        device_id  TEXT    NOT NULL,
        started_at TEXT    NOT NULL,
        ended_at   TEXT,
        is_active  INTEGER NOT NULL DEFAULT 1
      )''');
    await db.execute('CREATE INDEX idx_sessions_user ON sessions(user_id)');

    await _createLiveImu(db);
    await _createLiveLight(db);
    await _createLiveMic(db);
  }

  // ---------------------------------------------------------------------------
  // Schema migrations
  // ---------------------------------------------------------------------------

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS session_summary');
      await db.execute('DROP TABLE IF EXISTS sensor_snapshots');
      await db.execute('DROP TABLE IF EXISTS imu_data');
      // unified_telemetry created below in < 5 path
    }
    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS unified_telemetry');
      // unified_telemetry created below in < 5 path
    }
    if (oldVersion < 4) {
      await db.execute('DROP TABLE IF EXISTS unified_telemetry');
      // unified_telemetry created below in < 5 path
    }
    // v4 → v5: Replace the single unified_telemetry table with three
    // per-packet-type tables that match the new ble_live mainboard protocol.
    if (oldVersion < 5) {
      await _createLiveImu(db);
      await _createLiveLight(db);
      await _createLiveMic(db);
    }
  }

  // ---------------------------------------------------------------------------
  // Table DDL helpers
  // ---------------------------------------------------------------------------

  /// live_imu — mirrors LiveImuPacket / BleLiveImuPayload (0x50, 7 bytes)
  ///
  /// | Column         | Type    | Source field                        |
  /// |----------------|---------|-------------------------------------|
  /// | step_count     | INTEGER | uint32 LE bytes [1-4]               |
  /// | activity_state | INTEGER | uint8  byte  [5] (BleLiveActivity*) |
  Future<void> _createLiveImu(Database db) async {
    await db.execute('''
      CREATE TABLE live_imu (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id     INTEGER NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
        ts_ms          INTEGER NOT NULL,
        step_count     INTEGER NOT NULL,
        activity_state INTEGER NOT NULL
      )''');
    await db.execute(
        'CREATE INDEX idx_live_imu_ts ON live_imu(session_id, ts_ms)');
  }

  /// live_light — mirrors LiveLightPacket / BleLiveLightPayload (0x51, 3 bytes)
  ///
  /// | Column         | Type    | Source field                              |
  /// |----------------|---------|-------------------------------------------|
  /// | exposure_class | INTEGER | uint8 byte [1] (BleLiveLightExposure*)    |
  /// | intensity      | INTEGER | uint8 byte [2] light_color_intensity 0-255|
  Future<void> _createLiveLight(Database db) async {
    await db.execute('''
      CREATE TABLE live_light (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id     INTEGER NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
        ts_ms          INTEGER NOT NULL,
        exposure_class INTEGER NOT NULL,
        intensity      INTEGER NOT NULL
      )''');
    await db.execute(
        'CREATE INDEX idx_live_light_ts ON live_light(session_id, ts_ms)');
  }

  /// live_mic — mirrors LiveMicPacket / BleLiveMicPayload (0x52, 4 bytes)
  ///
  /// | Column    | Type    | Source field                            |
  /// |-----------|---------|-----------------------------------------|
  /// | env_class | INTEGER | uint8  byte  [1] (BleLiveEnvClass*)     |
  /// | laeq_x10  | INTEGER | uint16 LE bytes [2-3] (LAeq × 10 in dB)|
  Future<void> _createLiveMic(Database db) async {
    await db.execute('''
      CREATE TABLE live_mic (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
        ts_ms      INTEGER NOT NULL,
        env_class  INTEGER NOT NULL,
        laeq_x10   INTEGER NOT NULL
      )''');
    await db.execute(
        'CREATE INDEX idx_live_mic_ts ON live_mic(session_id, ts_ms)');
  }
}
