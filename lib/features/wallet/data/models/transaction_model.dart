import '../../domain/entities/transaction.dart';

class TransactionModel extends WalletTransaction {
  const TransactionModel({
    required super.id,
    required super.walletId,
    required super.type,
    required super.status,
    required super.amount,
    required super.fee,
    super.txHash,
    super.toAddress,
    super.fromAddress,
    super.confirmations,
    required super.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      walletId: json['wallet_id'] as String,
      type: TransactionType.values.byName(json['type'] as String),
      status: TransactionStatus.values.byName(json['status'] as String),
      amount: (json['amount'] as num).toDouble(),
      fee: (json['fee'] as num?)?.toDouble() ?? 0.0,
      txHash: json['tx_hash'] as String?,
      toAddress: json['to_address'] as String?,
      fromAddress: json['from_address'] as String?,
      confirmations: json['confirmations'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wallet_id': walletId,
      'type': type.name,
      'status': status.name,
      'amount': amount,
      'fee': fee,
      'tx_hash': txHash,
      'to_address': toAddress,
      'from_address': fromAddress,
      'confirmations': confirmations,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
