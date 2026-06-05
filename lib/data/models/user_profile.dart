/// Persistent user profile stored in the `users` table.
class UserProfile {
  final int? id;          // null before first DB insert
  final String name;
  final int? ageYears;
  final double? weightKg;
  final double? heightCm;
  final String createdAt; // ISO-8601

  const UserProfile({
    this.id,
    required this.name,
    this.ageYears,
    this.weightKg,
    this.heightCm,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'age': ageYears,
    'weight_kg': weightKg,
    'height_cm': heightCm,
    'created_at': createdAt,
  };

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
    id: m['id'] as int?,
    name: m['name'] as String,
    ageYears: m['age'] as int?,
    weightKg: m['weight_kg'] as double?,
    heightCm: m['height_cm'] as double?,
    createdAt: m['created_at'] as String,
  );

  UserProfile copyWith({
    int? id,
    String? name,
    int? ageYears,
    double? weightKg,
    double? heightCm,
  }) =>
      UserProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        ageYears: ageYears ?? this.ageYears,
        weightKg: weightKg ?? this.weightKg,
        heightCm: heightCm ?? this.heightCm,
        createdAt: createdAt,
      );
}
