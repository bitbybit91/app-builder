import '../../domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.username,
    required super.trustLevel,
    required super.tradeCount,
    required super.feedbackScore,
    super.feedbackPositive,
    super.feedbackNegative,
    required super.createdAt,
    super.lastSeen,
    super.bio,
    super.pgpPublicKey,
    super.isVerified,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      username: json['username'] as String,
      trustLevel: json['trust_level'] as String? ?? 'Unproven',
      tradeCount: json['trade_count'] as int? ?? 0,
      feedbackScore: (json['feedback_score'] as num?)?.toDouble() ?? 0,
      feedbackPositive: json['feedback_positive'] as int? ?? 0,
      feedbackNegative: json['feedback_negative'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastSeen: json['last_seen'] != null ? DateTime.parse(json['last_seen'] as String) : null,
      bio: json['bio'] as String?,
      pgpPublicKey: json['pgp_public_key'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
    );
  }
}
