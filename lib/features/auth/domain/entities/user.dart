import 'package:equatable/equatable.dart';

enum UserRole { user, moderator, admin }

enum TrustLevel { unproven, veryLow, low, average, high }

class User extends Equatable {
  const User({
    required this.id,
    required this.username,
    required this.role,
    required this.createdAt,
    this.email,
    this.publicPgpKey,
    this.tradeCount = 0,
    this.feedbackScore = 0,
    this.lastSeen,
    this.country,
    this.languages = const <String>[],
    this.twoFactorEnabled = false,
  });

  final String id;
  final String username;
  final String? email;
  final UserRole role;
  final DateTime createdAt;
  final String? publicPgpKey;
  final int tradeCount;
  final int feedbackScore;
  final DateTime? lastSeen;
  final String? country;
  final List<String> languages;
  final bool twoFactorEnabled;

  TrustLevel get trustLevel {
    if (tradeCount < 5) return TrustLevel.unproven;
    if (tradeCount < 10) return TrustLevel.veryLow;
    if (tradeCount < 25) return TrustLevel.low;
    if (tradeCount < 100) return TrustLevel.average;
    return TrustLevel.high;
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    UserRole? role,
    DateTime? createdAt,
    String? publicPgpKey,
    int? tradeCount,
    int? feedbackScore,
    DateTime? lastSeen,
    String? country,
    List<String>? languages,
    bool? twoFactorEnabled,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      publicPgpKey: publicPgpKey ?? this.publicPgpKey,
      tradeCount: tradeCount ?? this.tradeCount,
      feedbackScore: feedbackScore ?? this.feedbackScore,
      lastSeen: lastSeen ?? this.lastSeen,
      country: country ?? this.country,
      languages: languages ?? this.languages,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        username,
        email,
        role,
        createdAt,
        publicPgpKey,
        tradeCount,
        feedbackScore,
        lastSeen,
        country,
        languages,
        twoFactorEnabled,
      ];
}
