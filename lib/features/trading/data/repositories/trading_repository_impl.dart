import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/offer.dart';
import '../../domain/entities/trade.dart';
import '../../domain/repositories/trading_repository.dart';
import '../datasources/trading_remote_datasource.dart';

class TradingRepositoryImpl implements TradingRepository {
  final TradingRemoteDataSource _remoteDataSource;
  TradingRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Offer>> getOffers({String? coinType, OfferType? offerType, String? currency, int page = 1}) async {
    try {
      return await _remoteDataSource.getOffers(coinType: coinType, offerType: offerType, currency: currency, page: page);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<Offer> getOffer(String id) async {
    try {
      return await _remoteDataSource.getOffer(id);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<Offer> createOffer(Offer offer) async {
    try {
      return await _remoteDataSource.createOffer({
        'offer_type': offer.offerType.name,
        'trade_type': offer.tradeType.name,
        'coin_type': offer.coinType,
        'fiat_currency': offer.fiatCurrency,
        'price': offer.price,
        'min_amount': offer.minAmount,
        'max_amount': offer.maxAmount,
        'payment_method': offer.paymentMethod.name,
        'payment_details': offer.paymentDetails,
        'terms': offer.terms,
        'price_equation': offer.priceEquation,
        'margin_percentage': offer.marginPercentage,
        'country_code': offer.countryCode,
      });
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<Offer> updateOffer(Offer offer) async {
    try {
      return await _remoteDataSource.getOffer(offer.id); // Simplified
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<void> deleteOffer(String id) async {
    // Implementation would call delete endpoint
  }

  @override
  Future<Trade> initiateTrade(String offerId, double amount) async {
    try {
      return await _remoteDataSource.initiateTrade(offerId, amount);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<Trade> getTrade(String id) async {
    try {
      return await _remoteDataSource.getTrade(id);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<List<Trade>> getTrades({TradeStatus? status, int page = 1}) async {
    try {
      return await _remoteDataSource.getTrades(status: status, page: page);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<Trade> updateTradeStatus(String tradeId, TradeStatus status) async {
    try {
      return await _remoteDataSource.updateTradeStatus(tradeId, status);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<void> disputeTrade(String tradeId, String reason) async {
    try {
      await _remoteDataSource.updateTradeStatus(tradeId, TradeStatus.disputed);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }
}
