import 'package:sqflite/sqflite.dart';
import 'package:smart_wearables_app/data/database/app_database.dart';
import 'package:smart_wearables_app/data/models/live_packets.dart';
import 'package:smart_wearables_app/data/models/session_model.dart';
import 'package:smart_wearables_app/data/models/unified_telemetry.dart'; // TODO-REMOVE

/// Data-access object for session lifecycle and live-mode telemetry persistence.
class SessionDao {
  Future<Database> get _db => AppDatabase.instance.database;

  // ─── Session CRUD ──────────────────────────────────────────────────────────

  Future<SessionModel> insert(SessionModel session) async {
    final db = await _db;
    final id = await db.insert('sessions', session.toMap());
    return session.copyWith(id: id);
  }

  Future<void> closeSession(int id, DateTime endedAt) async {
    final db = await _db;
    await db.update(
      'sessions',
      {'ended_at': endedAt.toIso8601String(), 'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Returns the first session with [is_active = 1] for crash recovery.
  Future<SessionModel?> findIncompleteSession() async {
    final db = await _db;
    final rows = await db.query('sessions', where: 'is_active = 1', limit: 1);
    return rows.isEmpty ? null : SessionModel.fromMap(rows.first);
  }

  // ─── live_imu (0x50) ──────────────────────────────────────────────────────

  /// INSERT one IMU metrics row. Called on every 0x50 packet (~1 Hz).
  Future<void> insertImu(LiveImuPacket row) async {
    final db = await _db;
    await db.insert(
      'live_imu',
      row.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// All IMU rows for [sessionId], chronological.
  Future<List<LiveImuPacket>> getImuForSession(int sessionId) async {
    final db   = await _db;
    final rows = await db.query(
      'live_imu',
      where:    'session_id = ?',
      whereArgs: [sessionId],
      orderBy:  'ts_ms ASC',
    );
    return rows.map(LiveImuPacket.fromMap).toList();
  }

  /// Most-recent [limit] IMU rows for [sessionId], chronological.
  Future<List<LiveImuPacket>> getRecentImu(
      int sessionId, {int limit = 60}) async {
    final db   = await _db;
    final rows = await db.query(
      'live_imu',
      where:    'session_id = ?',
      whereArgs: [sessionId],
      orderBy:  'ts_ms DESC',
      limit:    limit,
    );
    return rows.map(LiveImuPacket.fromMap).toList().reversed.toList();
  }

  // ─── live_light (0x51) ────────────────────────────────────────────────────

  /// INSERT one light metrics row. Called on every 0x51 packet (~3 s, change-gated).
  Future<void> insertLight(LiveLightPacket row) async {
    final db = await _db;
    await db.insert(
      'live_light',
      row.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// All light rows for [sessionId], chronological.
  Future<List<LiveLightPacket>> getLightForSession(int sessionId) async {
    final db   = await _db;
    final rows = await db.query(
      'live_light',
      where:    'session_id = ?',
      whereArgs: [sessionId],
      orderBy:  'ts_ms ASC',
    );
    return rows.map(LiveLightPacket.fromMap).toList();
  }

  // ─── live_mic (0x52) ──────────────────────────────────────────────────────

  /// INSERT one mic metrics row. Called on every 0x52 packet (~3 s, change-gated).
  Future<void> insertMic(LiveMicPacket row) async {
    final db = await _db;
    await db.insert(
      'live_mic',
      row.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// All mic rows for [sessionId], chronological.
  Future<List<LiveMicPacket>> getMicForSession(int sessionId) async {
    final db   = await _db;
    final rows = await db.query(
      'live_mic',
      where:    'session_id = ?',
      whereArgs: [sessionId],
      orderBy:  'ts_ms ASC',
    );
    return rows.map(LiveMicPacket.fromMap).toList();
  }

  // ─── Weekly step summary (Fitness bar chart) ───────────────────────────────

  /// Returns the max step count per day for the last 7 days.
  /// Each entry: { 'day_of_week': 'Mon', 'max_steps': int }
  /// Uses MAX(step_count) per session per day — firmware reports cumulative
  /// steps since LIVE_START, so MAX gives the final tally for that session.
  Future<List<Map<String, dynamic>>> weeklyStepSummary() async {
    final db    = await _db;
    final today = DateTime.now();
    final since = today.subtract(const Duration(days: 6));
    final sinceStr =
        '${since.year}-${since.month.toString().padLeft(2, '0')}-${since.day.toString().padLeft(2, '0')}';

    final rows = await db.rawQuery('''
      SELECT
        substr(s.started_at, 1, 10) AS day,
        MAX(li.step_count)          AS steps
      FROM live_imu li
      INNER JOIN sessions s ON s.id = li.session_id
      WHERE substr(s.started_at, 1, 10) >= ?
      GROUP BY substr(s.started_at, 1, 10)
      ORDER BY day ASC
    ''', [sinceStr]);

    final Map<String, int> dayMap = {
      for (final r in rows)
        r['day'] as String: (r['steps'] as int? ?? 0),
    };

    const weekdayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return List.generate(7, (i) {
      final d   = since.add(Duration(days: i));
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      return {
        'day_of_week': weekdayNames[d.weekday],
        'max_steps':   dayMap[key] ?? 0,
      };
    });
  }

  // ─── Legacy unified telemetry — TODO-REMOVE ───────────────────────────────
  // Keep until BLE-sync workflow is migrated to the live-packet protocol.

  /// TODO-REMOVE: insertUnified writes to the old unified_telemetry table.
  /// That table no longer exists in schema v5 — this method is a no-op
  /// until the BLE-sync path is removed entirely.
  Future<void> insertUnified(UnifiedTelemetry row) async { // TODO-REMOVE
    // unified_telemetry was dropped in schema v5.
    // This is intentionally a no-op to prevent crashes while the
    // BLE-sync workflow is still being migrated.
  } // TODO-REMOVE

  /// TODO-REMOVE: getTelemetryForSession and getRecentTelemetry target the
  /// old unified_telemetry table. Return empty lists until removed.
  Future<List<UnifiedTelemetry>> getTelemetryForSession(int sessionId) async { // TODO-REMOVE
    return [];
  } // TODO-REMOVE

  Future<List<UnifiedTelemetry>> getRecentTelemetry( // TODO-REMOVE
      int sessionId, {int limit = 60}) async {
    return [];
  } // TODO-REMOVE
}
