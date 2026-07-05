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
      version: 9,
      onCreate:    _onCreate,
      onUpgrade:   _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Schema v7 — full creation (fresh install)
  // ---------------------------------------------------------------------------

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        name       TEXT    NOT NULL,
        gender     TEXT,
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

    await _createUnifiedTelemetry(db);
  }

  // ---------------------------------------------------------------------------
  // Schema migrations
  // ---------------------------------------------------------------------------

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Drop all old tables since we are in active dev and schema keeps shifting
    if (oldVersion < 8) {
      await db.execute('DROP TABLE IF EXISTS session_summary');
      await db.execute('DROP TABLE IF EXISTS sensor_snapshots');
      await db.execute('DROP TABLE IF EXISTS imu_data');
      await db.execute('DROP TABLE IF EXISTS live_imu');
      await db.execute('DROP TABLE IF EXISTS live_light');
      await db.execute('DROP TABLE IF EXISTS live_mic');
      await db.execute('DROP TABLE IF EXISTS unified_telemetry');
      await _createUnifiedTelemetry(db);
    }
    if (oldVersion < 9) {
      await db.execute('ALTER TABLE users ADD COLUMN gender TEXT;');
    }
  }

  // ---------------------------------------------------------------------------
  // Table DDL helpers
  // ---------------------------------------------------------------------------

  Future<void> _createUnifiedTelemetry(Database db) async {
    await db.execute('''
      CREATE TABLE unified_telemetry (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id       INTEGER NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
        ts_ms            INTEGER NOT NULL,
        step_count       INTEGER NOT NULL,
        light_class      INTEGER NOT NULL,
        blue_clear_ratio INTEGER NOT NULL,
        color_temp       INTEGER NOT NULL,
        laeq_x10         INTEGER NOT NULL,
        audio_class      INTEGER NOT NULL
      )''');
    await db.execute(
        'CREATE INDEX idx_unified_telemetry_ts ON unified_telemetry(session_id, ts_ms)');
  }
}
