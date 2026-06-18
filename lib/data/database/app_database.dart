import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Singleton SQLite database helper.
///
/// Schema version history:
///   v1 — multi-table: users, sessions, imu_data, sensor_snapshots,
///         session_summary (fragmented high-frequency model).
///   v2 — unified_telemetry replaces imu_data, sensor_snapshots,
///         session_summary. MCU now performs all DSP; app stores 1 Hz
///         fused snapshots only.
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
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Schema v2 — full creation
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
    await db.execute(
        'CREATE INDEX idx_sessions_user ON sessions(user_id)');

    await _createUnifiedTelemetry(db);
  }

  // ---------------------------------------------------------------------------
  // Schema migration v1 → v2
  // ---------------------------------------------------------------------------

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Drop fragmented high-frequency tables from v1
      await db.execute('DROP TABLE IF EXISTS session_summary');
      await db.execute('DROP TABLE IF EXISTS sensor_snapshots');
      await db.execute('DROP TABLE IF EXISTS imu_data');
      // Add unified 1 Hz telemetry table
      await _createUnifiedTelemetry(db);
    }
  }

  Future<void> _createUnifiedTelemetry(Database db) async {
    await db.execute('''
      CREATE TABLE unified_telemetry (
        id                    INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id            INTEGER NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
        ts_ms                 INTEGER NOT NULL,
        step_count            INTEGER NOT NULL,
        cadence               INTEGER NOT NULL,
        activity_state        INTEGER NOT NULL,
        uv_risk               REAL    NOT NULL,
        blue_light_intensity  INTEGER NOT NULL,
        blue_light_ratio      REAL    NOT NULL,
        sun_like_index        REAL    NOT NULL,
        clear_channel         INTEGER NOT NULL
      )''');
    await db.execute(
        'CREATE INDEX idx_unified_ts ON unified_telemetry(session_id, ts_ms)');
  }
}
