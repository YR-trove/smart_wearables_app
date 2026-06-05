class UserProfile {
  final int?    id;
  final String  name;
  final int?    age;
  final double? weightKg;
  final double? heightCm;

  const UserProfile({
    this.id,
    required this.name,
    this.age,
    this.weightKg,
    this.heightCm,
  });

  UserProfile copyWith({
    int?    id,
    String? name,
    int?    age,
    double? weightKg,
    double? heightCm,
  }) => UserProfile(
    id:       id       ?? this.id,
    name:     name     ?? this.name,
    age:      age      ?? this.age,
    weightKg: weightKg ?? this.weightKg,
    heightCm: heightCm ?? this.heightCm,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name':      name,
    'age':       age,
    'weight_kg': weightKg,
    'height_cm': heightCm,
  };

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
    id:       m['id']        as int?,
    name:     m['name']      as String,
    age:      m['age']       as int?,
    weightKg: m['weight_kg'] as double?,
    heightCm: m['height_cm'] as double?,
  );
}
