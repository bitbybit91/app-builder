import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:capital_monero/core/errors/failures.dart';
import 'package:capital_monero/features/trading/domain/entities/offer_entity.dart';
import 'package:capital_monero/features/trading/domain/repositories/trading_repository.dart';

@injectable
class GetOfferUseCase {
  final TradingRepository _repository;

  const GetOfferUseCase(this._repository);

  Future<Either<Failure, OfferEntity>> call(String id) =>
      _repository.getOffer(id);
}
