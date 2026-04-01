import '../entities/offer.dart';
import '../repositories/trading_repository.dart';

class GetOffersUseCase {
  final TradingRepository _repository;
  GetOffersUseCase(this._repository);

  Future<List<Offer>> call({String? coinType, OfferType? offerType, String? currency, int page = 1}) {
    return _repository.getOffers(coinType: coinType, offerType: offerType, currency: currency, page: page);
  }
}
