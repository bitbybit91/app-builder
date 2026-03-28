class Wallet {
  final int id;
  final int userId;
  final String crypto;
  final String? address;
  final double balance;
  final double lockedBalance;
  final double availableBalance;
  final DateTime createdAt;

  const Wallet({
    required this.id,
    required this.userId,
    required this.crypto,
    this.address,
    required this.balance,
    required this.lockedBalance,
    required this.availableBalance,
    required this.createdAt,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      crypto: json['crypto'] as String,
      address: json['address'] as String?,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      lockedBalance: (json['locked_balance'] as num?)?.toDouble() ?? 0.0,
      availableBalance: (json['available_balance'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'crypto': crypto,
      'address': address,
      'balance': balance,
      'locked_balance': lockedBalance,
      'available_balance': availableBalance,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Wallet copyWith({
    int? id,
    int? userId,
    String? crypto,
    String? address,
    double? balance,
    double? lockedBalance,
    double? availableBalance,
    DateTime? createdAt,
  }) {
    return Wallet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      crypto: crypto ?? this.crypto,
      address: address ?? this.address,
      balance: balance ?? this.balance,
      lockedBalance: lockedBalance ?? this.lockedBalance,
      availableBalance: availableBalance ?? this.availableBalance,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Wallet && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Wallet(id: $id, crypto: $crypto, balance: $balance)';
}
