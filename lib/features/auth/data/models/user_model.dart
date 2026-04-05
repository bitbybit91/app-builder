import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.username,
    super.email,
    super.isTwoFactorEnabled,
    super.isVerified,
    super.trustLevel,
    super.tradeCount,
    super.feedbackScore,
    required super.createdAt,
    super.lastSeen,
    super.pgpPublicKey,
    super.bio,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String?,
      isTwoFactorEnabled: json['is_two_factor_enabled'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
      trustLevel: json['trust_level'] as String? ?? 'Unproven',
      tradeCount: json['trade_count'] as int? ?? 0,
      feedbackScore: (json['feedback_score'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'] as String)
          : null,
      pgpPublicKey: json['pgp_public_key'] as String?,
      bio: json['bio'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'is_two_factor_enabled': isTwoFactorEnabled,
      'is_verified': isVerified,
      'trust_level': trustLevel,
      'trade_count': tradeCount,
      'feedback_score': feedbackScore,
      'created_at': createdAt.toIso8601String(),
      'last_seen': lastSeen?.toIso8601String(),
      'pgp_public_key': pgpPublicKey,
      'bio': bio,
    };
  }
}
