import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/offer.dart';
import '../../domain/repositories/offers_repository.dart';
import '../datasources/offers_remote_datasource.dart';

class OffersRepositoryImpl implements OffersRepository {
  final OffersRemoteDataSource _remoteDataSource;

  OffersRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<Offer>>> getOffers({
    String? tradeType,
    String? cryptoCurrency,
    String? fiatCurrency,
    String? paymentMethod,
    String? countryCode,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final offers = await _remoteDataSource.getOffers(
        tradeType: tradeType,
        cryptoCurrency: cryptoCurrency,
        fiatCurrency: fiatCurrency,
        paymentMethod: paymentMethod,
        countryCode: countryCode,
        page: page,
        limit: limit,
      );
      return Right(offers);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, Offer>> getOfferById(String id) async {
    try {
      final offer = await _remoteDataSource.getOfferById(id);
      return Right(offer);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
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
  }) async {
    try {
      final offer = await _remoteDataSource.createOffer({
        'trade_type': tradeType,
        'offer_type': offerType,
        'crypto_currency': cryptoCurrency,
        'fiat_currency': fiatCurrency,
        'payment_method': paymentMethod,
        if (fixedPrice != null) 'fixed_price': fixedPrice,
        if (marketPriceMargin != null) 'market_price_margin': marketPriceMargin,
        'min_amount': minAmount,
        'max_amount': maxAmount,
        if (terms != null) 'terms': terms,
        if (countryCode != null) 'country_code': countryCode,
      });
      return Right(offer);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, Offer>> updateOffer({
    required String id,
    double? fixedPrice,
    double? marketPriceMargin,
    double? minAmount,
    double? maxAmount,
    String? terms,
    bool? isActive,
  }) async {
    try {
      final offer = await _remoteDataSource.updateOffer(id, {
        if (fixedPrice != null) 'fixed_price': fixedPrice,
        if (marketPriceMargin != null) 'market_price_margin': marketPriceMargin,
        if (minAmount != null) 'min_amount': minAmount,
        if (maxAmount != null) 'max_amount': maxAmount,
        if (terms != null) 'terms': terms,
        if (isActive != null) 'is_active': isActive,
      });
      return Right(offer);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteOffer(String id) async {
    try {
      await _remoteDataSource.deleteOffer(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, List<Offer>>> getMyOffers() async {
    try {
      final offers = await _remoteDataSource.getMyOffers();
      return Right(offers);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(UnexpectedFailure());
    }
  }
}
