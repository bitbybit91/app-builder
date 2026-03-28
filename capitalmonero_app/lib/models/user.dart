class User {
  final int id;
  final String username;
  final String name;
  final String email;
  final String role;
  final bool isActive;
  final bool twoFactorEnabled;
  final double? btcBalance;
  final double? xmrBalance;
  final double? escrowBtc;
  final double? escrowXmr;
  final String? btcDepositAddress;
  final String? xmrDepositAddress;
  final int completedTrades;
  final double rating;
  final String? bio;
  final String? avatar;
  final String? country;
  final String preferredCurrency;
  final int positiveFeedback;
  final int negativeFeedback;
  final double feedbackScore;
  final bool isAdmin;
  final bool isBanned;
  final DateTime? lastSeenAt;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    required this.twoFactorEnabled,
    this.btcBalance,
    this.xmrBalance,
    this.escrowBtc,
    this.escrowXmr,
    this.btcDepositAddress,
    this.xmrDepositAddress,
    required this.completedTrades,
    required this.rating,
    this.bio,
    this.avatar,
    this.country,
    required this.preferredCurrency,
    required this.positiveFeedback,
    required this.negativeFeedback,
    required this.feedbackScore,
    required this.isAdmin,
    required this.isBanned,
    this.lastSeenAt,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'user',
      isActive: json['is_active'] as bool? ?? true,
      twoFactorEnabled: json['two_factor_enabled'] as bool? ?? false,
      btcBalance: (json['btc_balance'] as num?)?.toDouble(),
      xmrBalance: (json['xmr_balance'] as num?)?.toDouble(),
      escrowBtc: (json['escrow_btc'] as num?)?.toDouble(),
      escrowXmr: (json['escrow_xmr'] as num?)?.toDouble(),
      btcDepositAddress: json['btc_deposit_address'] as String?,
      xmrDepositAddress: json['xmr_deposit_address'] as String?,
      completedTrades: json['completed_trades'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      bio: json['bio'] as String?,
      avatar: json['avatar'] as String?,
      country: json['country'] as String?,
      preferredCurrency: json['preferred_currency'] as String? ?? 'USD',
      positiveFeedback: json['positive_feedback'] as int? ?? 0,
      negativeFeedback: json['negative_feedback'] as int? ?? 0,
      feedbackScore: (json['feedback_score'] as num?)?.toDouble() ?? 0.0,
      isAdmin: json['is_admin'] as bool? ?? false,
      isBanned: json['is_banned'] as bool? ?? false,
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.parse(json['last_seen_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'email': email,
      'role': role,
      'is_active': isActive,
      'two_factor_enabled': twoFactorEnabled,
      'btc_balance': btcBalance,
      'xmr_balance': xmrBalance,
      'escrow_btc': escrowBtc,
      'escrow_xmr': escrowXmr,
      'btc_deposit_address': btcDepositAddress,
      'xmr_deposit_address': xmrDepositAddress,
      'completed_trades': completedTrades,
      'rating': rating,
      'bio': bio,
      'avatar': avatar,
      'country': country,
      'preferred_currency': preferredCurrency,
      'positive_feedback': positiveFeedback,
      'negative_feedback': negativeFeedback,
      'feedback_score': feedbackScore,
      'is_admin': isAdmin,
      'is_banned': isBanned,
      'last_seen_at': lastSeenAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  User copyWith({
    int? id,
    String? username,
    String? name,
    String? email,
    String? role,
    bool? isActive,
    bool? twoFactorEnabled,
    double? btcBalance,
    double? xmrBalance,
    double? escrowBtc,
    double? escrowXmr,
    String? btcDepositAddress,
    String? xmrDepositAddress,
    int? completedTrades,
    double? rating,
    String? bio,
    String? avatar,
    String? country,
    String? preferredCurrency,
    int? positiveFeedback,
    int? negativeFeedback,
    double? feedbackScore,
    bool? isAdmin,
    bool? isBanned,
    DateTime? lastSeenAt,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      btcBalance: btcBalance ?? this.btcBalance,
      xmrBalance: xmrBalance ?? this.xmrBalance,
      escrowBtc: escrowBtc ?? this.escrowBtc,
      escrowXmr: escrowXmr ?? this.escrowXmr,
      btcDepositAddress: btcDepositAddress ?? this.btcDepositAddress,
      xmrDepositAddress: xmrDepositAddress ?? this.xmrDepositAddress,
      completedTrades: completedTrades ?? this.completedTrades,
      rating: rating ?? this.rating,
      bio: bio ?? this.bio,
      avatar: avatar ?? this.avatar,
      country: country ?? this.country,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      positiveFeedback: positiveFeedback ?? this.positiveFeedback,
      negativeFeedback: negativeFeedback ?? this.negativeFeedback,
      feedbackScore: feedbackScore ?? this.feedbackScore,
      isAdmin: isAdmin ?? this.isAdmin,
      isBanned: isBanned ?? this.isBanned,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is User && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'User(id: $id, username: $username)';
}
