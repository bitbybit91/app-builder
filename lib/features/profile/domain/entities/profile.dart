import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String username;
  final double feedbackScore;
  final int tradeCount;
  final String trustLevel;
  final DateTime accountCreated;
  final DateTime lastSeen;
  final String? bio;
  final bool isVerified;

  const UserProfile({
    required this.id,
    required this.username,
    required this.feedbackScore,
    required this.tradeCount,
    required this.trustLevel,
    required this.accountCreated,
    required this.lastSeen,
    this.bio,
    this.isVerified = false,
  });

  @override
  List<Object?> get props => [id, username, feedbackScore, tradeCount];
}
