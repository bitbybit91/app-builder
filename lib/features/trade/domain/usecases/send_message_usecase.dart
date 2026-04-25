import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:capital_monero/core/errors/failures.dart';
import 'package:capital_monero/features/trade/domain/entities/trade_entity.dart';
import 'package:capital_monero/features/trade/domain/repositories/trade_repository.dart';

@injectable
class SendMessageUseCase {
  final TradeRepository _repository;
  const SendMessageUseCase(this._repository);
  Future<Either<Failure, ChatMessage>> call(String tradeId, String content) =>
      _repository.sendMessage(tradeId, content);
}
