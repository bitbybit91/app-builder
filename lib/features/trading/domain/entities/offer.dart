import 'package:equatable/equatable.dart';

enum OfferType { buy, sell }
enum TradeType { online, localCash }
enum PaymentMethod { bankTransfer, cash, cryptoToCrypto, revolut, paypal, other }

class Offer extends Equatable {
  final String id;
  final String userId;
  final String username;
  final OfferType offerType;
  final TradeType tradeType;
  final String coinType; // XMR or BTC
  final String fiatCurrency;
  final double price;
  final double minAmount;
  final double maxAmount;
  final PaymentMethod paymentMethod;
  final String? paymentDetails;
  final String? terms;
  final String priceEquation;
  final double marginPercentage;
  final String? countryCode;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Offer({
    required this.id,
    required this.userId,
    required this.username,
    required this.offerType,
    required this.tradeType,
    required this.coinType,
    required this.fiatCurrency,
    required this.price,
    required this.minAmount,
    required this.maxAmount,
    required this.paymentMethod,
    this.paymentDetails,
    this.terms,
    this.priceEquation = 'market_price',
    this.marginPercentage = 0.0,
    this.countryCode,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, userId, offerType, coinType, price];
}
