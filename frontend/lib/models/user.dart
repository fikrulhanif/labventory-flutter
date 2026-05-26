/// Mirrors `UserResource` on the backend (Requirements 1.7, 12.4).
class User {
  const User({
    required this.id,
    required this.name,
    this.nim,
    required this.email,
    required this.role,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final String? nim;
  final String email;

  /// One of "admin" | "laboran" | "student".
  final String role;

  /// One of "active" | "inactive".
  final String status;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isStudent => role == 'student';
  bool get isActive => status == 'active';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      nim: json['nim'] as String?,
      email: json['email'] as String,
      role: json['role'] as String,
      status: json['status'] as String,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nim': nim,
      'email': email,
      'role': role,
      'status': status,
      'created_at': createdAt?.toUtc().toIso8601String(),
      'updated_at': updatedAt?.toUtc().toIso8601String(),
    };
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw);
    }
    return null;
  }
}
