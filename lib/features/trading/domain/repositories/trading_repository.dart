import '../entities/offer.dart';
import '../entities/trade.dart';

abstract class TradingRepository {
  Future<List<Offer>> getOffers({String? coinType, OfferType? offerType, String? currency, int page = 1});
  Future<Offer> getOffer(String id);
  Future<Offer> createOffer(Offer offer);
  Future<Offer> updateOffer(Offer offer);
  Future<void> deleteOffer(String id);
  Future<Trade> initiateTrade(String offerId, double amount);
  Future<Trade> getTrade(String id);
  Future<List<Trade>> getTrades({TradeStatus? status, int page = 1});
  Future<Trade> updateTradeStatus(String tradeId, TradeStatus status);
  Future<void> disputeTrade(String tradeId, String reason);
}
