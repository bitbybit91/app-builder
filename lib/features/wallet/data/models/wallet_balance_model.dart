import '../../domain/entities/wallet_balance.dart';

class WalletBalanceModel extends WalletBalance {
  const WalletBalanceModel({
    required super.currency,
    required super.available,
    required super.pending,
    required super.total,
    super.depositAddress,
    required super.updatedAt,
  });

  factory WalletBalanceModel.fromJson(Map<String, dynamic> json) {
    return WalletBalanceModel(
      currency: json['currency'] as String,
      available: (json['available'] as num).toDouble(),
      pending: (json['pending'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      depositAddress: json['deposit_address'] as String?,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
