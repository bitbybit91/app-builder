import '../../domain/entities/wallet_transaction.dart';

class WalletTransactionModel extends WalletTransaction {
  const WalletTransactionModel({
    required super.id,
    required super.currency,
    required super.type,
    required super.amount,
    super.fee,
    super.txHash,
    super.address,
    required super.status,
    super.confirmations,
    super.requiredConfirmations,
    required super.createdAt,
    super.confirmedAt,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id'] as String,
      currency: json['currency'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      fee: (json['fee'] as num?)?.toDouble(),
      txHash: json['tx_hash'] as String?,
      address: json['address'] as String?,
      status: json['status'] as String,
      confirmations: json['confirmations'] as int? ?? 0,
      requiredConfirmations: json['required_confirmations'] as int? ?? 10,
      createdAt: DateTime.parse(json['created_at'] as String),
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'] as String)
          : null,
    );
  }
}
