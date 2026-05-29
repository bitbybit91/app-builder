import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.username,
    required super.role,
    required super.createdAt,
    super.email,
    super.publicPgpKey,
    super.tradeCount,
    super.feedbackScore,
    super.lastSeen,
    super.country,
    super.languages,
    super.twoFactorEnabled,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String?,
      role: _parseRole(json['role'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
      publicPgpKey: json['public_pgp_key'] as String?,
      tradeCount: (json['trade_count'] as num?)?.toInt() ?? 0,
      feedbackScore: (json['feedback_score'] as num?)?.toInt() ?? 0,
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'] as String)
          : null,
      country: json['country'] as String?,
      languages: (json['languages'] as List<dynamic>?)
              ?.map((dynamic e) => e as String)
              .toList() ??
          const <String>[],
      twoFactorEnabled: json['two_factor_enabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'username': username,
        'email': email,
        'role': role.name,
        'created_at': createdAt.toIso8601String(),
        'public_pgp_key': publicPgpKey,
        'trade_count': tradeCount,
        'feedback_score': feedbackScore,
        'last_seen': lastSeen?.toIso8601String(),
        'country': country,
        'languages': languages,
        'two_factor_enabled': twoFactorEnabled,
      };

  static UserRole _parseRole(String? raw) {
    switch (raw) {
      case 'admin':
        return UserRole.admin;
      case 'moderator':
        return UserRole.moderator;
      default:
        return UserRole.user;
    }
  }
}
