class ProfileData {
  const ProfileData({
    required this.name,
    required this.email,
    required this.bio,
  });

  final String name;
  final String email;
  final String bio;

  bool get isEmpty => name.trim().isEmpty && email.trim().isEmpty && bio.trim().isEmpty;
  bool get isNotEmpty => !isEmpty;

  ProfileData copyWith({
    String? name,
    String? email,
    String? bio,
  }) {
    return ProfileData(
      name: name ?? this.name,
      email: email ?? this.email,
      bio: bio ?? this.bio,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': 1,
      'name': name,
      'email': email,
      'bio': bio,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory ProfileData.fromMap(Map<String, Object?> map) {
    return ProfileData(
      name: (map['name'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      bio: (map['bio'] as String?) ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileData &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          email == other.email &&
          bio == other.bio;

  @override
  int get hashCode => Object.hash(name, email, bio);
}

