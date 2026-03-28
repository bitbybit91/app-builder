class Transaction {
  final int id;
  final int userId;
  final int? walletId;
  final String? txid;
  final String crypto;
  final String type;
  final double amount;
  final double? fee;
  final String? address;
  final String status;
  final int confirmations;
  final int requiredConfirmations;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.userId,
    this.walletId,
    this.txid,
    required this.crypto,
    required this.type,
    required this.amount,
    this.fee,
    this.address,
    required this.status,
    required this.confirmations,
    required this.requiredConfirmations,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      walletId: json['wallet_id'] as int?,
      txid: json['txid'] as String?,
      crypto: json['crypto'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      fee: (json['fee'] as num?)?.toDouble(),
      address: json['address'] as String?,
      status: json['status'] as String,
      confirmations: json['confirmations'] as int? ?? 0,
      requiredConfirmations: json['required_confirmations'] as int? ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'wallet_id': walletId,
      'txid': txid,
      'crypto': crypto,
      'type': type,
      'amount': amount,
      'fee': fee,
      'address': address,
      'status': status,
      'confirmations': confirmations,
      'required_confirmations': requiredConfirmations,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Transaction copyWith({
    int? id,
    int? userId,
    int? walletId,
    String? txid,
    String? crypto,
    String? type,
    double? amount,
    double? fee,
    String? address,
    String? status,
    int? confirmations,
    int? requiredConfirmations,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      walletId: walletId ?? this.walletId,
      txid: txid ?? this.txid,
      crypto: crypto ?? this.crypto,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      fee: fee ?? this.fee,
      address: address ?? this.address,
      status: status ?? this.status,
      confirmations: confirmations ?? this.confirmations,
      requiredConfirmations:
          requiredConfirmations ?? this.requiredConfirmations,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transaction &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Transaction(id: $id, crypto: $crypto, type: $type, amount: $amount)';
}
