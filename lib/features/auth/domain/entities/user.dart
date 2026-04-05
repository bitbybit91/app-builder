import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String username;
  final String? email;
  final bool isTwoFactorEnabled;
  final bool isVerified;
  final String trustLevel;
  final int tradeCount;
  final double feedbackScore;
  final DateTime createdAt;
  final DateTime? lastSeen;
  final String? pgpPublicKey;
  final String? bio;

  const User({
    required this.id,
    required this.username,
    this.email,
    this.isTwoFactorEnabled = false,
    this.isVerified = false,
    this.trustLevel = 'Unproven',
    this.tradeCount = 0,
    this.feedbackScore = 0,
    required this.createdAt,
    this.lastSeen,
    this.pgpPublicKey,
    this.bio,
  });

  @override
  List<Object?> get props => [
        id,
        username,
        email,
        isTwoFactorEnabled,
        isVerified,
        trustLevel,
        tradeCount,
        feedbackScore,
        createdAt,
        lastSeen,
        pgpPublicKey,
        bio,
      ];
}
