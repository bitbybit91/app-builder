import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/offer.dart';

abstract class OffersRepository {
  Future<Either<Failure, List<Offer>>> getOffers({
    String? tradeType,
    String? cryptoCurrency,
    String? fiatCurrency,
    String? paymentMethod,
    String? countryCode,
    int page = 1,
    int limit = 20,
  });

  Future<Either<Failure, Offer>> getOfferById(String id);

  Future<Either<Failure, Offer>> createOffer({
    required String tradeType,
    required String offerType,
    required String cryptoCurrency,
    required String fiatCurrency,
    required String paymentMethod,
    double? fixedPrice,
    double? marketPriceMargin,
    required double minAmount,
    required double maxAmount,
    String? terms,
    String? countryCode,
  });

  Future<Either<Failure, Offer>> updateOffer({
    required String id,
    double? fixedPrice,
    double? marketPriceMargin,
    double? minAmount,
    double? maxAmount,
    String? terms,
    bool? isActive,
  });

  Future<Either<Failure, void>> deleteOffer(String id);

  Future<Either<Failure, List<Offer>>> getMyOffers();
}
