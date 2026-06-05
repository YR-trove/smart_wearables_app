/// One recording session stored in the `sessions` table.
class SessionModel {
  final int? id;           // null before first DB insert
  final int userId;
  final String deviceId;   // BLE MAC / name
  final String startedAt;  // ISO-8601
  final String? endedAt;   // null while session is active
  final bool isActive;

  const SessionModel({
    this.id,
    required this.userId,
    required this.deviceId,
    required this.startedAt,
    this.endedAt,
    this.isActive = true,
  });

  Duration get elapsed {
    final start = DateTime.parse(startedAt);
    final end = endedAt != null ? DateTime.parse(endedAt!) : DateTime.now();
    return end.difference(start);
  }

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'device_id': deviceId,
    'started_at': startedAt,
    'ended_at': endedAt,
    'is_active': isActive ? 1 : 0,
  };

  factory SessionModel.fromMap(Map<String, dynamic> m) => SessionModel(
    id: m['id'] as int?,
    userId: m['user_id'] as int,
    deviceId: m['device_id'] as String,
    startedAt: m['started_at'] as String,
    endedAt: m['ended_at'] as String?,
    isActive: (m['is_active'] as int) == 1,
  );
}
