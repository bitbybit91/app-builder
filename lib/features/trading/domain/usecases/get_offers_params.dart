import 'package:equatable/equatable.dart';

import 'package:capital_monero/features/trading/domain/entities/offer_entity.dart';

class GetOffersParams extends Equatable {
  final String? currency;
  final String? fiatCurrency;
  final OfferType? type;
  final String? paymentMethod;

  const GetOffersParams({
    this.currency,
    this.fiatCurrency,
    this.type,
    this.paymentMethod,
  });

  @override
  List<Object?> get props => [currency, fiatCurrency, type, paymentMethod];

  @override
  bool get stringify => true;
}
