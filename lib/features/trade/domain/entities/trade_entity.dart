import 'package:equatable/equatable.dart';

enum TradeStatus {
  open,
  funded,
  escrow,
  released,
  disputed,
  cancelled,
  complete,
}

class TradeEntity extends Equatable {
  final String id;
  final String offerId;
  final String buyerId;
  final String sellerId;
  final TradeStatus status;
  final double amount;
  final double price;
  final String cryptoCurrency;
  final String fiatCurrency;
  final String paymentMethod;
  final String? escrowTxId;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const TradeEntity({
    required this.id,
    required this.offerId,
    required this.buyerId,
    required this.sellerId,
    required this.status,
    required this.amount,
    required this.price,
    required this.cryptoCurrency,
    required this.fiatCurrency,
    required this.paymentMethod,
    this.escrowTxId,
    required this.createdAt,
    this.expiresAt,
  });

  factory TradeEntity.fromJson(Map<String, dynamic> json) => TradeEntity(
        id: json['id'] as String,
        offerId: json['offer_id'] as String,
        buyerId: json['buyer_id'] as String,
        sellerId: json['seller_id'] as String,
        status: TradeStatus.values.byName(json['status'] as String),
        amount: (json['amount'] as num).toDouble(),
        price: (json['price'] as num).toDouble(),
        cryptoCurrency: json['crypto_currency'] as String,
        fiatCurrency: json['fiat_currency'] as String,
        paymentMethod: json['payment_method'] as String,
        escrowTxId: json['escrow_tx_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        expiresAt: json['expires_at'] != null
            ? DateTime.parse(json['expires_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'offer_id': offerId,
        'buyer_id': buyerId,
        'seller_id': sellerId,
        'status': status.name,
        'amount': amount,
        'price': price,
        'crypto_currency': cryptoCurrency,
        'fiat_currency': fiatCurrency,
        'payment_method': paymentMethod,
        'escrow_tx_id': escrowTxId,
        'created_at': createdAt.toIso8601String(),
        'expires_at': expiresAt?.toIso8601String(),
      };

  TradeEntity copyWith({
    String? id,
    String? offerId,
    String? buyerId,
    String? sellerId,
    TradeStatus? status,
    double? amount,
    double? price,
    String? cryptoCurrency,
    String? fiatCurrency,
    String? paymentMethod,
    String? escrowTxId,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) =>
      TradeEntity(
        id: id ?? this.id,
        offerId: offerId ?? this.offerId,
        buyerId: buyerId ?? this.buyerId,
        sellerId: sellerId ?? this.sellerId,
        status: status ?? this.status,
        amount: amount ?? this.amount,
        price: price ?? this.price,
        cryptoCurrency: cryptoCurrency ?? this.cryptoCurrency,
        fiatCurrency: fiatCurrency ?? this.fiatCurrency,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        escrowTxId: escrowTxId ?? this.escrowTxId,
        createdAt: createdAt ?? this.createdAt,
        expiresAt: expiresAt ?? this.expiresAt,
      );

  @override
  List<Object?> get props => [
        id,
        offerId,
        buyerId,
        sellerId,
        status,
        amount,
        price,
        cryptoCurrency,
        fiatCurrency,
        paymentMethod,
        escrowTxId,
        createdAt,
        expiresAt,
      ];

  @override
  bool get stringify => true;
}

class ChatMessage extends Equatable {
  final String id;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final bool isRead;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.isRead = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        senderId: json['sender_id'] as String,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        isRead: json['is_read'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender_id': senderId,
        'content': content,
        'created_at': createdAt.toIso8601String(),
        'is_read': isRead,
      };

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? content,
    DateTime? createdAt,
    bool? isRead,
  }) =>
      ChatMessage(
        id: id ?? this.id,
        senderId: senderId ?? this.senderId,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
        isRead: isRead ?? this.isRead,
      );

  @override
  List<Object?> get props => [id, senderId, content, createdAt, isRead];

  @override
  bool get stringify => true;
}
