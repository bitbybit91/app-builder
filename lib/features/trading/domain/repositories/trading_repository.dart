import 'package:dartz/dartz.dart';

import 'package:capital_monero/core/errors/failures.dart';
import 'package:capital_monero/features/trading/domain/entities/create_offer_params.dart';
import 'package:capital_monero/features/trading/domain/entities/offer_entity.dart';

abstract interface class TradingRepository {
  Future<Either<Failure, List<OfferEntity>>> getOffers({
    String? currency,
    String? fiatCurrency,
    OfferType? type,
    String? paymentMethod,
  });

  Future<Either<Failure, OfferEntity>> getOffer(String id);

  Future<Either<Failure, OfferEntity>> createOffer(CreateOfferParams params);

  Future<Either<Failure, void>> cancelOffer(String id);
}
