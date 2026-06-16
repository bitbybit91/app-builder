import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/offer.dart';
import '../repositories/offers_repository.dart';

class CreateOfferUseCase extends UseCase<Offer, CreateOfferParams> {
  final OffersRepository repository;

  CreateOfferUseCase(this.repository);

  @override
  Future<Either<Failure, Offer>> call(CreateOfferParams params) {
    return repository.createOffer(
      tradeType: params.tradeType,
      offerType: params.offerType,
      cryptoCurrency: params.cryptoCurrency,
      fiatCurrency: params.fiatCurrency,
      paymentMethod: params.paymentMethod,
      fixedPrice: params.fixedPrice,
      marketPriceMargin: params.marketPriceMargin,
      minAmount: params.minAmount,
      maxAmount: params.maxAmount,
      terms: params.terms,
      countryCode: params.countryCode,
    );
  }
}

class CreateOfferParams {
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

  const CreateOfferParams({
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
}
