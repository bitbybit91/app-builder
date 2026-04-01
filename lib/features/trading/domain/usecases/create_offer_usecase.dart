import '../entities/offer.dart';
import '../repositories/trading_repository.dart';

class CreateOfferUseCase {
  final TradingRepository _repository;
  CreateOfferUseCase(this._repository);

  Future<Offer> call(Offer offer) {
    return _repository.createOffer(offer);
  }
}
