import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Singleton SQLite database.
/// Schema version history:
///   v1 — initial: users, sessions, imu_data, sensor_snapshots, session_summary
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = join(await getDatabasesPath(), 'smart_wearables.db');
    return openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        // Enable foreign key enforcement
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // ── Users ────────────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE users (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        name        TEXT    NOT NULL,
        age         INTEGER,
        weight_kg   REAL,
        height_cm   REAL,
        created_at  TEXT    NOT NULL
      )
    ''');

    // ── Sessions ─────────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE sessions (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        device_id   TEXT    NOT NULL,
        started_at  TEXT    NOT NULL,
        ended_at    TEXT,
        is_active   INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // ── IMU data (step_count + reserved metric3) ──────────────────────────────
    await db.execute('''
      CREATE TABLE imu_data (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id  INTEGER NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
        ts_ms       INTEGER NOT NULL,
        step_count  INTEGER NOT NULL,
        metric3     REAL
      )
    ''');

    // ── Shared sensor snapshots (light + mic) ─────────────────────────────────
    // sensor_type: 'light' | 'mic'
    // light → f1=uvRisk, f2=blueLightIntensity, f3=blueLightRatio,
    //         f4=sunLikeIndex, f5=metric1
    // mic   → f1=noiseLevel, f2=noiseTime, f3=metric2, f4=NULL, f5=NULL
    await db.execute('''
      CREATE TABLE sensor_snapshots (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id  INTEGER NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
        ts_ms       INTEGER NOT NULL,
        sensor_type TEXT    NOT NULL,
        f1          REAL,
        f2          REAL,
        f3          REAL,
        f4          REAL,
        f5          REAL
      )
    ''');

    // ── Session summary (aggregates, written on endSession + checkpoints) ─────
    await db.execute('''
      CREATE TABLE session_summary (
        session_id        INTEGER PRIMARY KEY REFERENCES sessions(id) ON DELETE CASCADE,
        total_steps       INTEGER,
        peak_noise_db     REAL,
        noise_dose_pct    REAL,
        noise_exposure_s  REAL,
        bluelight_dose    REAL,
        avg_uv_risk       REAL,
        avg_sun_like_idx  REAL
      )
    ''');

    // ── Indexes ───────────────────────────────────────────────────────────────
    await db.execute('CREATE INDEX idx_sessions_user   ON sessions(user_id)');
    await db.execute('CREATE INDEX idx_imu_session      ON imu_data(session_id, ts_ms)');
    await db.execute('CREATE INDEX idx_snap_session     ON sensor_snapshots(session_id, sensor_type, ts_ms)');
  }

  /// Increment version and add ALTER TABLE statements here for future fields.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Example for v2:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE session_summary ADD COLUMN avg_hrv REAL');
    // }
  }

  Future<void> close() async {
    final d = _db;
    if (d != null) {
      await d.close();
      _db = null;
    }
  }
}
