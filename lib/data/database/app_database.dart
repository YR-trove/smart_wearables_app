import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Schema v3 — full creation
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
  // Schema migrations
  // ---------------------------------------------------------------------------

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS session_summary');
      await db.execute('DROP TABLE IF EXISTS sensor_snapshots');
      await db.execute('DROP TABLE IF EXISTS imu_data');
      await _createUnifiedTelemetry(db);
    }
    
    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS unified_telemetry');
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
        color_temp            INTEGER NOT NULL,
        clear_channel         INTEGER NOT NULL,
        noise_db_spl          INTEGER NOT NULL,
        noise_db_fs           INTEGER NOT NULL
      )''');
    await db.execute(
        'CREATE INDEX idx_unified_ts ON unified_telemetry(session_id, ts_ms)');
  }
}