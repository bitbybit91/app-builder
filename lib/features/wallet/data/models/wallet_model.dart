import '../../domain/entities/wallet.dart';

class WalletModel extends Wallet {
  const WalletModel({
    required super.id,
    required super.coinType,
    required super.balance,
    required super.pendingBalance,
    required super.depositAddress,
    required super.lastUpdated,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'] as String,
      coinType: json['coin_type'] as String,
      balance: (json['balance'] as num).toDouble(),
      pendingBalance: (json['pending_balance'] as num?)?.toDouble() ?? 0.0,
      depositAddress: json['deposit_address'] as String,
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coin_type': coinType,
      'balance': balance,
      'pending_balance': pendingBalance,
      'deposit_address': depositAddress,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}
