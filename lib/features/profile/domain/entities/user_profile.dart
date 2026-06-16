import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String username;
  final String trustLevel;
  final int tradeCount;
  final double feedbackScore;
  final int feedbackPositive;
  final int feedbackNegative;
  final DateTime createdAt;
  final DateTime? lastSeen;
  final String? bio;
  final String? pgpPublicKey;
  final bool isVerified;

  const UserProfile({
    required this.username,
    required this.trustLevel,
    required this.tradeCount,
    required this.feedbackScore,
    this.feedbackPositive = 0,
    this.feedbackNegative = 0,
    required this.createdAt,
    this.lastSeen,
    this.bio,
    this.pgpPublicKey,
    this.isVerified = false,
  });

  @override
  List<Object?> get props => [username, trustLevel, tradeCount, feedbackScore];
}
