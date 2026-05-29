import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/trade.dart';

class TradeFilter {
  const TradeFilter({this.activeOnly = false, this.role, this.coin});
  final bool activeOnly;
  final TradeRole? role;
  final String? coin;
}

abstract class TradeRepository {
  Future<Either<Failure, Trade>> openTrade({
    required String offerId,
    required String buyerUsername,
    required String sellerUsername,
    required String coin,
    required String fiatCurrency,
    required double fiatAmount,
    required double cryptoAmount,
    required String paymentMethod,
  });

  Future<Either<Failure, Trade>> getTrade(String id);

  Future<Either<Failure, List<Trade>>> history({
    required String username,
    TradeFilter filter = const TradeFilter(),
  });

  Future<Either<Failure, Trade>> fundEscrow(String tradeId);
  Future<Either<Failure, Trade>> markPaymentSent(String tradeId);
  Future<Either<Failure, Trade>> markPaymentReceived(String tradeId);
  Future<Either<Failure, Trade>> releaseEscrow(String tradeId);
  Future<Either<Failure, Trade>> cancelTrade(String tradeId);
  Future<Either<Failure, Trade>> openDispute(String tradeId, String reason);

  Future<Either<Failure, List<TradeMessage>>> messages(String tradeId);
  Future<Either<Failure, TradeMessage>> sendMessage({
    required String tradeId,
    required String fromUsername,
    required String body,
    bool encrypted = false,
  });
}
