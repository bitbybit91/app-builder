import 'package:equatable/equatable.dart';

import 'package:capital_monero/features/trading/domain/entities/offer_entity.dart';

class CreateOfferParams extends Equatable {
  final OfferType type;
  final String cryptoCurrency;
  final String fiatCurrency;
  final double minAmount;
  final double maxAmount;
  final double price;
  final String paymentMethod;
  final String description;

  const CreateOfferParams({
    required this.type,
    required this.cryptoCurrency,
    required this.fiatCurrency,
    required this.minAmount,
    required this.maxAmount,
    required this.price,
    required this.paymentMethod,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'crypto_currency': cryptoCurrency,
        'fiat_currency': fiatCurrency,
        'min_amount': minAmount,
        'max_amount': maxAmount,
        'price': price,
        'payment_method': paymentMethod,
        'description': description,
      };

  @override
  List<Object?> get props => [
        type,
        cryptoCurrency,
        fiatCurrency,
        minAmount,
        maxAmount,
        price,
        paymentMethod,
        description,
      ];

  @override
  bool get stringify => true;
}
