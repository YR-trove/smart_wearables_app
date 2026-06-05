class UserProfile {
  final int?    id;
  final String  name;
  final int?    age;
  final double? weightKg;
  final double? heightCm;
  final DateTime createdAt;

  UserProfile({
    this.id,
    required this.name,
    this.age,
    this.weightKg,
    this.heightCm,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  UserProfile copyWith({
    int?    id,
    String? name,
    int?    age,
    double? weightKg,
    double? heightCm,
    DateTime? createdAt,
  }) => UserProfile(
    id:        id        ?? this.id,
    name:      name      ?? this.name,
    age:       age       ?? this.age,
    weightKg:  weightKg  ?? this.weightKg,
    heightCm:  heightCm  ?? this.heightCm,
    createdAt: createdAt ?? this.createdAt,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name':       name,
    'age':        age,
    'weight_kg':  weightKg,
    'height_cm':  heightCm,
    'created_at': createdAt.toIso8601String(),   // required NOT NULL column
  };

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
    id:        m['id']         as int?,
    name:      m['name']       as String,
    age:       m['age']        as int?,
    weightKg:  m['weight_kg']  as double?,
    heightCm:  m['height_cm']  as double?,
    createdAt: DateTime.parse(m['created_at'] as String),
  );
}
