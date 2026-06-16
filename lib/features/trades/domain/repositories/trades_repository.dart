import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/trade.dart';
import '../entities/trade_message.dart';

abstract class TradesRepository {
  Future<Either<Failure, List<Trade>>> getTrades({
    String? status,
    int page = 1,
    int limit = 20,
  });
  Future<Either<Failure, Trade>> getTradeById(String id);
  Future<Either<Failure, Trade>> createTrade({
    required String offerId,
    required double fiatAmount,
  });
  Future<Either<Failure, void>> markAsPaid(String tradeId);
  Future<Either<Failure, void>> releaseTrade(String tradeId);
  Future<Either<Failure, void>> cancelTrade(String tradeId, {String? reason});
  Future<Either<Failure, void>> disputeTrade(String tradeId, {required String reason});
  Future<Either<Failure, List<TradeMessage>>> getTradeMessages(String tradeId);
  Future<Either<Failure, TradeMessage>> sendTradeMessage({
    required String tradeId,
    required String content,
    bool encrypt = false,
  });
}
