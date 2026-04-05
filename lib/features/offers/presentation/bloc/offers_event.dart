part of 'offers_bloc.dart';

abstract class OffersEvent extends Equatable {
  const OffersEvent();
  @override
  List<Object?> get props => [];
}

class OffersLoadRequested extends OffersEvent {
  final String? tradeType;
  final String? cryptoCurrency;
  final String? fiatCurrency;
  final String? paymentMethod;
  final String? countryCode;

  const OffersLoadRequested({
    this.tradeType,
    this.cryptoCurrency,
    this.fiatCurrency,
    this.paymentMethod,
    this.countryCode,
  });

  @override
  List<Object?> get props => [tradeType, cryptoCurrency, fiatCurrency, paymentMethod, countryCode];
}

class OffersRefreshRequested extends OffersEvent {
  const OffersRefreshRequested();
}

class OffersLoadMoreRequested extends OffersEvent {
  const OffersLoadMoreRequested();
}

class OfferCreateRequested extends OffersEvent {
  final String tradeType;
  final String offerType;
  final String cryptoCurrency;
  final String fiatCurrency;
  final String paymentMethod;
  final double? fixedPrice;
  final double? marketPriceMargin;
  final double minAmount;
  final double maxAmount;
  final String? terms;
  final String? countryCode;

  const OfferCreateRequested({
    required this.tradeType,
    required this.offerType,
    required this.cryptoCurrency,
    required this.fiatCurrency,
    required this.paymentMethod,
    this.fixedPrice,
    this.marketPriceMargin,
    required this.minAmount,
    required this.maxAmount,
    this.terms,
    this.countryCode,
  });

  @override
  List<Object?> get props => [
        tradeType,
        offerType,
        cryptoCurrency,
        fiatCurrency,
        paymentMethod,
        fixedPrice,
        marketPriceMargin,
        minAmount,
        maxAmount,
        terms,
        countryCode,
      ];
}

class OffersFilterChanged extends OffersEvent {
  final String? tradeType;
  final String? cryptoCurrency;
  final String? fiatCurrency;
  final String? paymentMethod;
  final String? countryCode;

  const OffersFilterChanged({
    this.tradeType,
    this.cryptoCurrency,
    this.fiatCurrency,
    this.paymentMethod,
    this.countryCode,
  });

  @override
  List<Object?> get props => [tradeType, cryptoCurrency, fiatCurrency, paymentMethod, countryCode];
}
