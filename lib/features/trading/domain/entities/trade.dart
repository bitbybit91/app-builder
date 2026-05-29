import 'package:equatable/equatable.dart';

enum TradeStatus {
  created,
  funded,
  paymentSent,
  paymentReceived,
  released,
  cancelled,
  disputed,
  resolvedForBuyer,
  resolvedForSeller,
}

enum TradeRole { buyer, seller }

class Trade extends Equatable {
  const Trade({
    required this.id,
    required this.offerId,
    required this.buyerUsername,
    required this.sellerUsername,
    required this.coin,
    required this.fiatCurrency,
    required this.fiatAmount,
    required this.cryptoAmount,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.escrowAddress,
    this.escrowFundedAt,
    this.releasedAt,
    this.disputeReason,
  });

  final String id;
  final String offerId;
  final String buyerUsername;
  final String sellerUsername;
  final String coin;
  final String fiatCurrency;
  final double fiatAmount;
  final double cryptoAmount;
  final String paymentMethod;
  final TradeStatus status;
  final DateTime createdAt;
  final String? escrowAddress;
  final DateTime? escrowFundedAt;
  final DateTime? releasedAt;
  final String? disputeReason;

  bool get isActive => switch (status) {
        TradeStatus.created ||
        TradeStatus.funded ||
        TradeStatus.paymentSent ||
        TradeStatus.paymentReceived ||
        TradeStatus.disputed =>
          true,
        _ => false,
      };

  TradeRole roleFor(String username) =>
      username == buyerUsername ? TradeRole.buyer : TradeRole.seller;

  Trade copyWith({
    TradeStatus? status,
    String? escrowAddress,
    DateTime? escrowFundedAt,
    DateTime? releasedAt,
    String? disputeReason,
  }) {
    return Trade(
      id: id,
      offerId: offerId,
      buyerUsername: buyerUsername,
      sellerUsername: sellerUsername,
      coin: coin,
      fiatCurrency: fiatCurrency,
      fiatAmount: fiatAmount,
      cryptoAmount: cryptoAmount,
      paymentMethod: paymentMethod,
      status: status ?? this.status,
      createdAt: createdAt,
      escrowAddress: escrowAddress ?? this.escrowAddress,
      escrowFundedAt: escrowFundedAt ?? this.escrowFundedAt,
      releasedAt: releasedAt ?? this.releasedAt,
      disputeReason: disputeReason ?? this.disputeReason,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id, offerId, buyerUsername, sellerUsername, coin, fiatCurrency,
        fiatAmount, cryptoAmount, paymentMethod, status, createdAt,
        escrowAddress, escrowFundedAt, releasedAt, disputeReason,
      ];
}

class TradeMessage extends Equatable {
  const TradeMessage({
    required this.id,
    required this.tradeId,
    required this.fromUsername,
    required this.body,
    required this.sentAt,
    this.encrypted = false,
  });

  final String id;
  final String tradeId;
  final String fromUsername;
  final String body;
  final DateTime sentAt;
  final bool encrypted;

  @override
  List<Object?> get props =>
      <Object?>[id, tradeId, fromUsername, body, sentAt, encrypted];
}
