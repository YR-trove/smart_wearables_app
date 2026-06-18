import 'package:sqflite/sqflite.dart';
import 'package:smart_wearables_app/data/database/app_database.dart';
import 'package:smart_wearables_app/data/models/session_model.dart';
import 'package:smart_wearables_app/data/models/unified_telemetry.dart';

/// Data-access object for session lifecycle and telemetry persistence.
///
/// With the 1 Hz unified model every packet maps to one immediate INSERT;
/// there is no batching, flushing, or checkpoint logic in this layer.
class SessionDao {
  Future<Database> get _db => AppDatabase.instance.database;

  // ---------------------------------------------------------------------------
  // Session CRUD
  // ---------------------------------------------------------------------------

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

  /// Returns the first session with [is_active = 1], used for crash recovery.
  Future<SessionModel?> findIncompleteSession() async {
    final db = await _db;
    final rows = await db.query(
      'sessions',
      where: 'is_active = 1',
      limit: 1,
    );
    return rows.isEmpty ? null : SessionModel.fromMap(rows.first);
  }

  // ---------------------------------------------------------------------------
  // Unified telemetry — 1 Hz direct write
  // ---------------------------------------------------------------------------

  /// Inserts a single [UnifiedTelemetry] row immediately on packet receipt.
  /// No batching required at 1 Hz.
  Future<void> insertUnified(UnifiedTelemetry row) async {
    final db = await _db;
    await db.insert(
      'unified_telemetry',
      row.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ---------------------------------------------------------------------------
  // Telemetry queries
  // ---------------------------------------------------------------------------

  /// Returns all [UnifiedTelemetry] rows for [sessionId], ordered by time.
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

  /// Returns the last [limit] telemetry rows for [sessionId].
  /// Useful for populating a live dashboard without loading the full history.
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
}
