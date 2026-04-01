import '../../domain/entities/profile.dart';

class ProfileModel extends UserProfile {
  const ProfileModel({
    required super.id,
    required super.username,
    required super.feedbackScore,
    required super.tradeCount,
    required super.trustLevel,
    required super.accountCreated,
    required super.lastSeen,
    super.bio,
    super.isVerified,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      username: json['username'] as String,
      feedbackScore: (json['feedback_score'] as num).toDouble(),
      tradeCount: json['trade_count'] as int,
      trustLevel: json['trust_level'] as String,
      accountCreated: DateTime.parse(json['account_created'] as String),
      lastSeen: DateTime.parse(json['last_seen'] as String),
      bio: json['bio'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id, 'username': username, 'feedback_score': feedbackScore,
      'trade_count': tradeCount, 'trust_level': trustLevel,
      'account_created': accountCreated.toIso8601String(),
      'last_seen': lastSeen.toIso8601String(),
      'bio': bio, 'is_verified': isVerified,
    };
  }
}
