import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.username,
    super.email,
    super.isTotpEnabled,
    super.pgpPublicKey,
    super.trustLevel,
    super.feedbackScore,
    super.tradeCount,
    required super.createdAt,
    required super.lastSeen,
    super.isAdmin,
    super.isBanned,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String?,
      isTotpEnabled: json['is_totp_enabled'] as bool? ?? false,
      pgpPublicKey: json['pgp_public_key'] as String?,
      trustLevel: TrustLevel.values.byName(json['trust_level'] as String? ?? 'unproven'),
      feedbackScore: (json['feedback_score'] as num?)?.toDouble() ?? 0.0,
      tradeCount: json['trade_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastSeen: DateTime.parse(json['last_seen'] as String),
      isAdmin: json['is_admin'] as bool? ?? false,
      isBanned: json['is_banned'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'is_totp_enabled': isTotpEnabled,
      'pgp_public_key': pgpPublicKey,
      'trust_level': trustLevel.name,
      'feedback_score': feedbackScore,
      'trade_count': tradeCount,
      'created_at': createdAt.toIso8601String(),
      'last_seen': lastSeen.toIso8601String(),
      'is_admin': isAdmin,
      'is_banned': isBanned,
    };
  }
}
