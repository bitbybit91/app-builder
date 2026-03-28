class Swap {
  final int id;
  final int userId;
  final String fromCrypto;
  final String toCrypto;
  final double fromAmount;
  final double toAmount;
  final double rate;
  final double fee;
  final String status;
  final DateTime? completedAt;
  final DateTime createdAt;

  const Swap({
    required this.id,
    required this.userId,
    required this.fromCrypto,
    required this.toCrypto,
    required this.fromAmount,
    required this.toAmount,
    required this.rate,
    required this.fee,
    required this.status,
    this.completedAt,
    required this.createdAt,
  });

  factory Swap.fromJson(Map<String, dynamic> json) {
    return Swap(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      fromCrypto: json['from_crypto'] as String,
      toCrypto: json['to_crypto'] as String,
      fromAmount: (json['from_amount'] as num?)?.toDouble() ?? 0.0,
      toAmount: (json['to_amount'] as num?)?.toDouble() ?? 0.0,
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
      fee: (json['fee'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'from_crypto': fromCrypto,
      'to_crypto': toCrypto,
      'from_amount': fromAmount,
      'to_amount': toAmount,
      'rate': rate,
      'fee': fee,
      'status': status,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  Swap copyWith({
    int? id,
    int? userId,
    String? fromCrypto,
    String? toCrypto,
    double? fromAmount,
    double? toAmount,
    double? rate,
    double? fee,
    String? status,
    DateTime? completedAt,
    DateTime? createdAt,
  }) {
    return Swap(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fromCrypto: fromCrypto ?? this.fromCrypto,
      toCrypto: toCrypto ?? this.toCrypto,
      fromAmount: fromAmount ?? this.fromAmount,
      toAmount: toAmount ?? this.toAmount,
      rate: rate ?? this.rate,
      fee: fee ?? this.fee,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Swap && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Swap(id: $id, fromCrypto: $fromCrypto, toCrypto: $toCrypto, status: $status)';
}
