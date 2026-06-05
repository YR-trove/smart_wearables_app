class SessionModel {
  final int?     id;
  final int      userId;
  final String   deviceId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final bool     isActive;

  const SessionModel({
    this.id,
    required this.userId,
    required this.deviceId,
    required this.startedAt,
    this.endedAt,
    required this.isActive,
  });

  SessionModel copyWith({
    int?     id,
    int?     userId,
    String?  deviceId,
    DateTime? startedAt,
    DateTime? endedAt,
    bool?    isActive,
  }) => SessionModel(
    id:        id        ?? this.id,
    userId:    userId    ?? this.userId,
    deviceId:  deviceId  ?? this.deviceId,
    startedAt: startedAt ?? this.startedAt,
    endedAt:   endedAt   ?? this.endedAt,
    isActive:  isActive  ?? this.isActive,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'user_id':    userId,
    'device_id':  deviceId,
    'started_at': startedAt.toIso8601String(),
    'ended_at':   endedAt?.toIso8601String(),
    'is_active':  isActive ? 1 : 0,
  };

  factory SessionModel.fromMap(Map<String, dynamic> m) => SessionModel(
    id:        m['id']         as int?,
    userId:    m['user_id']    as int,
    deviceId:  m['device_id']  as String,
    startedAt: DateTime.parse(m['started_at'] as String),
    endedAt:   m['ended_at']  != null
                 ? DateTime.parse(m['ended_at'] as String)
                 : null,
    isActive:  (m['is_active'] as int) == 1,
  );
}
