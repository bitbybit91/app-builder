import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:capital_monero/core/errors/failures.dart';
import 'package:capital_monero/features/trade/domain/entities/trade_entity.dart';
import 'package:capital_monero/features/trade/domain/repositories/trade_repository.dart';

@injectable
class UpdateTradeStatusUseCase {
  final TradeRepository _repository;
  const UpdateTradeStatusUseCase(this._repository);
  Future<Either<Failure, TradeEntity>> call(String tradeId, TradeStatus status) =>
      _repository.updateTradeStatus(tradeId, status);
}
