import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:capital_monero/core/errors/failures.dart';
import 'package:capital_monero/features/trading/domain/entities/offer_entity.dart';
import 'package:capital_monero/features/trading/domain/repositories/trading_repository.dart';
import 'package:capital_monero/features/trading/domain/usecases/get_offers_params.dart';

@injectable
class GetOffersUseCase {
  final TradingRepository _repository;

  const GetOffersUseCase(this._repository);

  Future<Either<Failure, List<OfferEntity>>> call(GetOffersParams params) =>
      _repository.getOffers(
        currency: params.currency,
        fiatCurrency: params.fiatCurrency,
        type: params.type,
        paymentMethod: params.paymentMethod,
      );
}
