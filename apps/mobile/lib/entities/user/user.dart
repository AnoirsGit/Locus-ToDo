class User {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final String timezone;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    required this.timezone,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id:        json['id']       as String,
      email:     json['email']    as String,
      name:      json['name']     as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      timezone:  json['timezone'] as String? ?? 'UTC',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatarUrl': avatarUrl,
      'timezone': timezone,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
