import 'package:equatable/equatable.dart';

class ProfileEntity extends Equatable {
  final String id;
  final String username;
  final double reputationScore;
  final int tradesCount;
  final double successRate;
  final DateTime memberSince;
  final bool isVerified;
  final String? avatarUrl;
  final String? bio;

  const ProfileEntity({
    required this.id,
    required this.username,
    required this.reputationScore,
    required this.tradesCount,
    required this.successRate,
    required this.memberSince,
    required this.isVerified,
    this.avatarUrl,
    this.bio,
  });

  factory ProfileEntity.fromJson(Map<String, dynamic> json) => ProfileEntity(
        id: json['id'] as String,
        username: json['username'] as String,
        reputationScore: (json['reputation_score'] as num).toDouble(),
        tradesCount: json['trades_count'] as int,
        successRate: (json['success_rate'] as num).toDouble(),
        memberSince: DateTime.parse(json['member_since'] as String),
        isVerified: json['is_verified'] as bool? ?? false,
        avatarUrl: json['avatar_url'] as String?,
        bio: json['bio'] as String?,
      );

  ProfileEntity copyWith({
    String? id, String? username, double? reputationScore, int? tradesCount,
    double? successRate, DateTime? memberSince, bool? isVerified,
    String? avatarUrl, String? bio,
  }) => ProfileEntity(
        id: id ?? this.id, username: username ?? this.username,
        reputationScore: reputationScore ?? this.reputationScore,
        tradesCount: tradesCount ?? this.tradesCount,
        successRate: successRate ?? this.successRate,
        memberSince: memberSince ?? this.memberSince,
        isVerified: isVerified ?? this.isVerified,
        avatarUrl: avatarUrl ?? this.avatarUrl, bio: bio ?? this.bio,
      );

  @override
  List<Object?> get props => [id, username, reputationScore, tradesCount, successRate, memberSince, isVerified, avatarUrl, bio];
  @override bool get stringify => true;
}

class FeedbackEntity extends Equatable {
  final String id;
  final String fromUserId;
  final String fromUsername;
  final int rating;
  final String comment;
  final DateTime createdAt;

  const FeedbackEntity({
    required this.id,
    required this.fromUserId,
    required this.fromUsername,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory FeedbackEntity.fromJson(Map<String, dynamic> json) => FeedbackEntity(
        id: json['id'] as String,
        fromUserId: json['from_user_id'] as String,
        fromUsername: json['from_username'] as String,
        rating: json['rating'] as int,
        comment: json['comment'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  @override
  List<Object?> get props => [id, fromUserId, fromUsername, rating, comment, createdAt];
  @override bool get stringify => true;
}
