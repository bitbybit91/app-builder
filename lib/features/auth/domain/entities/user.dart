import 'package:equatable/equatable.dart';

enum TrustLevel { unproven, veryLow, low, average, high }

class User extends Equatable {
  final String id;
  final String username;
  final String? email;
  final bool isTotpEnabled;
  final String? pgpPublicKey;
  final TrustLevel trustLevel;
  final double feedbackScore;
  final int tradeCount;
  final DateTime createdAt;
  final DateTime lastSeen;
  final bool isAdmin;
  final bool isBanned;

  const User({
    required this.id,
    required this.username,
    this.email,
    this.isTotpEnabled = false,
    this.pgpPublicKey,
    this.trustLevel = TrustLevel.unproven,
    this.feedbackScore = 0.0,
    this.tradeCount = 0,
    required this.createdAt,
    required this.lastSeen,
    this.isAdmin = false,
    this.isBanned = false,
  });

  TrustLevel get calculatedTrustLevel {
    if (tradeCount < 5) return TrustLevel.unproven;
    if (feedbackScore < 50) return TrustLevel.veryLow;
    if (feedbackScore < 70) return TrustLevel.low;
    if (feedbackScore < 90) return TrustLevel.average;
    return TrustLevel.high;
  }

  @override
  List<Object?> get props => [id, username, email, isTotpEnabled, trustLevel, tradeCount];
}
