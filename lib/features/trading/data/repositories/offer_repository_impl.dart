import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/offer.dart';
import '../../domain/repositories/offer_repository.dart';
import '../datasources/trading_data_source.dart';

class OfferRepositoryImpl implements OfferRepository {
  OfferRepositoryImpl({required TradingDataSource source}) : _source = source;
  final TradingDataSource _source;


  @override
  Future<Either<Failure, List<Offer>>> listOffers(OfferQuery q) async {
    try {
      final List<Offer> result = await _source.listOffers(
        coin: q.coin,
        fiatCurrency: q.fiatCurrency,
        paymentMethod: q.paymentMethod,
        type: q.type,
        country: q.country,
        page: q.page,
        pageSize: q.pageSize,
        sortBy: q.sortBy,
      );
      return Right<Failure, List<Offer>>(result);
    } catch (e) {
      return Left<Failure, List<Offer>>(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Offer>> getOffer(String id) async {
    try {
      return Right<Failure, Offer>(await _source.getOffer(id));
    } on NotFoundException catch (e) {
      return Left<Failure, Offer>(NotFoundFailure(e.message));
    } catch (e) {
      return Left<Failure, Offer>(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Offer>> createOffer(Offer offer) async {
    if (offer.minAmount <= 0 || offer.maxAmount < offer.minAmount) {
      return const Left<Failure, Offer>(
        ValidationFailure('Invalid amount range'),
      );
    }
    try {
      return Right<Failure, Offer>(await _source.createOffer(offer));
    } catch (e) {
      return Left<Failure, Offer>(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Offer>> updateOffer(Offer offer) async {
    try {
      return Right<Failure, Offer>(await _source.updateOffer(offer));
    } on NotFoundException catch (e) {
      return Left<Failure, Offer>(NotFoundFailure(e.message));
    } catch (e) {
      return Left<Failure, Offer>(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteOffer(String id) async {
    try {
      await _source.deleteOffer(id);
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left<Failure, Unit>(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Offer>>> myOffers(String username) async {
    try {
      return Right<Failure, List<Offer>>(await _source.myOffers(username));
    } catch (e) {
      return Left<Failure, List<Offer>>(UnexpectedFailure(e.toString()));
    }
  }
}
