enum UserRole {
  player,
  coach,
  admin,
  academy,
  tournament,
}

class User {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? avatar;
  final String? phone;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.avatar,
    this.phone,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
        orElse: () => UserRole.player,
      ),
      avatar: json['avatar'],
      phone: json['phone'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.toString().split('.').last,
      'avatar': avatar,
      'phone': phone,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class AuthSession {
  final String token;
  final String refreshToken;
  final User user;
  final DateTime expiresAt;

  AuthSession({
    required this.token,
    required this.refreshToken,
    required this.user,
    required this.expiresAt,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: json['token'],
      refreshToken: json['refreshToken'],
      user: User.fromJson(json['user']),
      expiresAt: DateTime.parse(json['expiresAt']),
    );
  }
}

