import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/offer.dart';

class OfferQuery {
  const OfferQuery({
    this.coin,
    this.fiatCurrency,
    this.paymentMethod,
    this.type,
    this.country,
    this.page = 1,
    this.pageSize = 20,
    this.sortBy = 'price',
  });

  final String? coin;
  final String? fiatCurrency;
  final String? paymentMethod;
  final OfferType? type;
  final String? country;
  final int page;
  final int pageSize;
  final String sortBy;
}

abstract class OfferRepository {
  Future<Either<Failure, List<Offer>>> listOffers(OfferQuery query);
  Future<Either<Failure, Offer>> getOffer(String id);
  Future<Either<Failure, Offer>> createOffer(Offer offer);
  Future<Either<Failure, Offer>> updateOffer(Offer offer);
  Future<Either<Failure, Unit>> deleteOffer(String id);
  Future<Either<Failure, List<Offer>>> myOffers(String username);
}
