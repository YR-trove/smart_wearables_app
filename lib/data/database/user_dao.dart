import '../database/app_database.dart';
import '../models/user_profile.dart';

/// Data-access object for the `users` table.
/// Uses AppDatabase.instance directly — no constructor args needed.
class UserDao {
  /// Inserts a new user and returns the profile with its generated id.
  Future<UserProfile> insert(UserProfile profile) async {
    final db = await AppDatabase.instance.db;
    final id = await db.insert('users', profile.toMap());
    return profile.copyWith(id: id);
  }

  Future<UserProfile?> findById(int id) async {
    final db = await AppDatabase.instance.db;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return UserProfile.fromMap(rows.first);
  }

  Future<List<UserProfile>> findAll() async {
    final db = await AppDatabase.instance.db;
    final rows = await db.query('users', orderBy: 'created_at DESC');
    return rows.map(UserProfile.fromMap).toList();
  }

  Future<void> update(UserProfile profile) async {
    assert(profile.id != null, 'Cannot update a UserProfile without an id');
    final db = await AppDatabase.instance.db;
    await db.update(
      'users',
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.instance.db;
    // ON DELETE CASCADE removes sessions and all child rows automatically.
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }
}
