import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:capital_monero/core/errors/failures.dart';
import 'package:capital_monero/features/trading/domain/entities/create_offer_params.dart';
import 'package:capital_monero/features/trading/domain/entities/offer_entity.dart';
import 'package:capital_monero/features/trading/domain/repositories/trading_repository.dart';

@injectable
class CreateOfferUseCase {
  final TradingRepository _repository;

  const CreateOfferUseCase(this._repository);

  Future<Either<Failure, OfferEntity>> call(CreateOfferParams params) =>
      _repository.createOffer(params);
}
