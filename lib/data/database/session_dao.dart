import 'package:sqflite/sqflite.dart';
import 'package:smart_wearables_app/data/database/app_database.dart';
import 'package:smart_wearables_app/data/models/live_packets.dart';
import 'package:smart_wearables_app/data/models/session_model.dart';

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

  // ─── Unified Telemetry (0x55) ──────────────────────────────────────────────

  /// INSERT one unified metrics row. Called on every 0x55 packet (~2 Hz).
  Future<void> insertUnifiedPacket(UnifiedLivePacket row) async {
    final db = await _db;
    await db.insert(
      'unified_telemetry',
      row.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// All unified rows for [sessionId], chronological.
  Future<List<UnifiedLivePacket>> getUnifiedForSession(int sessionId) async {
    final db   = await _db;
    final rows = await db.query(
      'unified_telemetry',
      where:    'session_id = ?',
      whereArgs: [sessionId],
      orderBy:  'ts_ms ASC',
    );
    return rows.map(UnifiedLivePacket.fromMap).toList();
  }

  /// Most-recent [limit] unified rows for [sessionId], chronological.
  Future<List<UnifiedLivePacket>> getRecentUnified(
      int sessionId, {int limit = 60}) async {
    final db   = await _db;
    final rows = await db.query(
      'unified_telemetry',
      where:    'session_id = ?',
      whereArgs: [sessionId],
      orderBy:  'ts_ms DESC',
      limit:    limit,
    );
    return rows.map(UnifiedLivePacket.fromMap).toList().reversed.toList();
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
      FROM unified_telemetry li
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

}
