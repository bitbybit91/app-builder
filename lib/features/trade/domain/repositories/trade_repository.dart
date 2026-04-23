import 'package:dartz/dartz.dart';
import 'package:capital_monero/core/errors/failures.dart';
import 'package:capital_monero/features/trade/domain/entities/trade_entity.dart';

abstract interface class TradeRepository {
  Future<Either<Failure, TradeEntity>> getTrade(String id);
  Future<Either<Failure, List<ChatMessage>>> getMessages(String tradeId);
  Future<Either<Failure, ChatMessage>> sendMessage(String tradeId, String content);
  Future<Either<Failure, TradeEntity>> updateTradeStatus(String tradeId, TradeStatus status);
  Future<Either<Failure, void>> openDispute(String tradeId, String reason);
}
