import '../access_control_service.dart';

class UserProfile {
  final String userId;
  final String email;
  final UserRole role; // operator, creator, trader
  final DateTime createdAt;
  final DateTime lastActive;
  final Map<String, dynamic>
      preferences; // theme, layout, notification_settings

  UserProfile({
    required this.userId,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.lastActive,
    this.preferences = const {},
  });

  UserProfile copyWith({
    String? email,
    UserRole? role,
    DateTime? lastActive,
    Map<String, dynamic>? preferences,
  }) {
    return UserProfile(
      userId: userId,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt,
      lastActive: lastActive ?? this.lastActive,
      preferences: preferences ?? this.preferences,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'role': role.index,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
      'preferences': preferences,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'],
      email: json['email'],
      role: UserRole.values[json['role']],
      createdAt: DateTime.parse(json['createdAt']),
      lastActive: DateTime.parse(json['lastActive']),
      preferences: json['preferences'] ?? {},
    );
  }
}
