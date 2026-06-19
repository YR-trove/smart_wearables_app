import 'package:sqflite/sqflite.dart';
import 'package:smart_wearables_app/data/database/app_database.dart';
import 'package:smart_wearables_app/data/models/session_model.dart';
import 'package:smart_wearables_app/data/models/unified_telemetry.dart';

/// Data-access object for session lifecycle and telemetry persistence.
class SessionDao {
  Future<Database> get _db => AppDatabase.instance.database;

  // ─── Session CRUD ────────────────────────────────────────────────────────────

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

  // ─── Unified telemetry ───────────────────────────────────────────────────────

  /// Single immediate INSERT on every 1 Hz packet.
  Future<void> insertUnified(UnifiedTelemetry row) async {
    final db = await _db;
    await db.insert(
      'unified_telemetry',
      row.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<UnifiedTelemetry>> getTelemetryForSession(int sessionId) async {
    final db = await _db;
    final rows = await db.query(
      'unified_telemetry',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'ts_ms ASC',
    );
    return rows.map(UnifiedTelemetry.fromMap).toList();
  }

  Future<List<UnifiedTelemetry>> getRecentTelemetry(
      int sessionId, {int limit = 60}) async {
    final db = await _db;
    final rows = await db.query(
      'unified_telemetry',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'ts_ms DESC',
      limit: limit,
    );
    return rows.map(UnifiedTelemetry.fromMap).toList().reversed.toList();
  }

  // ─── Weekly step summary (Fitness bar chart) ─────────────────────────────────

  /// Returns the max step count per day for the last 7 days.
  /// Each entry: { 'day': 'YYYY-MM-DD', 'steps': int }
  /// Uses MAX(step_count) per session joined on its started_at date to avoid
  /// double-counting cumulative firmware step values.
  Future<List<Map<String, dynamic>>> weeklyStepSummary() async {
    final db = await _db;
    
    // Generate the last 7 days to ensure we always return 7 items
    final today = DateTime.now();
    final since = today.subtract(const Duration(days: 6));
    final sinceStr = since.toIso8601String().substring(0, 10);

    // Query the database for the max steps per day
    final rows = await db.rawQuery('''
      SELECT
        substr(s.started_at, 1, 10)  AS day,
        MAX(ut.step_count)           AS steps
      FROM unified_telemetry ut
      INNER JOIN sessions s ON s.id = ut.session_id
      WHERE substr(s.started_at, 1, 10) >= ?
      GROUP BY substr(s.started_at, 1, 10)
      ORDER BY day ASC
    ''', [sinceStr]);

    // Map the SQL results into a quick lookup dictionary
    final Map<String, int> dayMap = {
      for (final r in rows)
        r['day'] as String: (r['steps'] as int? ?? 0),
    };

    // Helper list to convert DateTime.weekday (1-7) to UI strings
    const weekdayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Generate exactly 7 days of data, filling in zeros where needed
    return List.generate(7, (i) {
      final d = since.add(Duration(days: i));
      final key = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
      
      return {
        'day_of_week': weekdayNames[d.weekday], // e.g., 'Mon'
        'max_steps': dayMap[key] ?? 0,          // The step count or 0
      };
    });
  }


}
