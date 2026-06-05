import '../database/app_database.dart';
import '../models/session_model.dart';
import '../models/session_summary.dart';
import '../models/imu_sample.dart';
import '../models/light_sample.dart';
import '../models/mic_sample.dart';

/// Data-access object for sessions, sensor data, and session summaries.
class SessionDao {
  // ── Session CRUD ─────────────────────────────────────────────────────────

  Future<SessionModel> insert(SessionModel session) async {
    final db = await AppDatabase.instance.db;
    final id = await db.insert('sessions', session.toMap());
    return SessionModel(
      id: id,
      userId: session.userId,
      deviceId: session.deviceId,
      startedAt: session.startedAt,
      endedAt: session.endedAt,
      isActive: session.isActive,
    );
  }

  Future<List<SessionModel>> findByUser(int userId) async {
    final db = await AppDatabase.instance.db;
    final rows = await db.query(
      'sessions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'started_at DESC',
    );
    return rows.map(SessionModel.fromMap).toList();
  }

  /// Returns any session that is still marked active (crash recovery).
  Future<SessionModel?> findActiveSession(int userId) async {
    final db = await AppDatabase.instance.db;
    final rows = await db.query(
      'sessions',
      where: 'user_id = ? AND is_active = 1 AND ended_at IS NULL',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return SessionModel.fromMap(rows.first);
  }

  Future<void> closeSession(int sessionId, String endedAt) async {
    final db = await AppDatabase.instance.db;
    await db.update(
      'sessions',
      {'ended_at': endedAt, 'is_active': 0},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  // ── Batch sensor writes ──────────────────────────────────────────────────

  /// Inserts a batch of IMU samples in a single transaction.
  Future<void> flushImu(int sessionId, List<ImuSample> samples) async {
    if (samples.isEmpty) return;
    final db = await AppDatabase.instance.db;
    await db.transaction((txn) async {
      final b = txn.batch();
      for (final s in samples) {
        b.insert('imu_data', s.toMap(sessionId));
      }
      await b.commit(noResult: true);
    });
  }

  /// Inserts a batch of light sensor samples in a single transaction.
  Future<void> flushLight(int sessionId, List<LightSample> samples) async {
    if (samples.isEmpty) return;
    final db = await AppDatabase.instance.db;
    await db.transaction((txn) async {
      final b = txn.batch();
      for (final s in samples) {
        b.insert('sensor_snapshots', s.toMap(sessionId));
      }
      await b.commit(noResult: true);
    });
  }

  /// Inserts a batch of mic samples in a single transaction.
  Future<void> flushMic(int sessionId, List<MicSample> samples) async {
    if (samples.isEmpty) return;
    final db = await AppDatabase.instance.db;
    await db.transaction((txn) async {
      final b = txn.batch();
      for (final s in samples) {
        b.insert('sensor_snapshots', s.toMap(sessionId));
      }
      await b.commit(noResult: true);
    });
  }

  // ── Session summary (upsert) ─────────────────────────────────────────────

  Future<void> upsertSummary(SessionSummary summary) async {
    final db = await AppDatabase.instance.db;
    await db.insert(
      'session_summary',
      summary.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<SessionSummary?> findSummary(int sessionId) async {
    final db = await AppDatabase.instance.db;
    final rows = await db.query(
      'session_summary',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
    if (rows.isEmpty) return null;
    return SessionSummary.fromMap(rows.first);
  }
}
