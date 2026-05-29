import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/trade.dart';
import '../../domain/repositories/trade_repository.dart';
import '../datasources/trading_data_source.dart';

class TradeRepositoryImpl implements TradeRepository {
  TradeRepositoryImpl({required TradingDataSource source}) : _source = source;
  final TradingDataSource _source;

  @override
  Future<Either<Failure, Trade>> openTrade({
    required String offerId,
    required String buyerUsername,
    required String sellerUsername,
    required String coin,
    required String fiatCurrency,
    required double fiatAmount,
    required double cryptoAmount,
    required String paymentMethod,
  }) async {
    try {
      final Trade trade = await _source.openTrade(Trade(
        id: '',
        offerId: offerId,
        buyerUsername: buyerUsername,
        sellerUsername: sellerUsername,
        coin: coin,
        fiatCurrency: fiatCurrency,
        fiatAmount: fiatAmount,
        cryptoAmount: cryptoAmount,
        paymentMethod: paymentMethod,
        status: TradeStatus.created,
        createdAt: DateTime.now(),
      ));
      return Right<Failure, Trade>(trade);
    } catch (e) {
      return Left<Failure, Trade>(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Trade>> getTrade(String id) async {
    try {
      return Right<Failure, Trade>(await _source.getTrade(id));
    } on NotFoundException catch (e) {
      return Left<Failure, Trade>(NotFoundFailure(e.message));
    } catch (e) {
      return Left<Failure, Trade>(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Trade>>> history({
    required String username,
    TradeFilter filter = const TradeFilter(),
  }) async {
    try {
      List<Trade> list =
          await _source.tradeHistory(username, activeOnly: filter.activeOnly);
      if (filter.coin != null) {
        list = list.where((Trade t) => t.coin == filter.coin).toList();
      }
      if (filter.role != null) {
        list = list.where((Trade t) => t.roleFor(username) == filter.role).toList();
      }
      return Right<Failure, List<Trade>>(list);
    } catch (e) {
      return Left<Failure, List<Trade>>(UnexpectedFailure(e.toString()));
    }
  }

  Future<Either<Failure, Trade>> _transition(String tradeId, Trade Function(Trade) f) async {
    try {
      final Trade current = await _source.getTrade(tradeId);
      final Trade updated = await _source.updateTrade(f(current));
      return Right<Failure, Trade>(updated);
    } on NotFoundException catch (e) {
      return Left<Failure, Trade>(NotFoundFailure(e.message));
    } catch (e) {
      return Left<Failure, Trade>(TradeFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Trade>> fundEscrow(String tradeId) => _transition(
        tradeId,
        (Trade t) => t.copyWith(
          status: TradeStatus.funded,
          escrowAddress: 'escrow_${t.coin}_${t.id.substring(0, 8)}',
          escrowFundedAt: DateTime.now(),
        ),
      );

  @override
  Future<Either<Failure, Trade>> markPaymentSent(String tradeId) => _transition(
        tradeId,
        (Trade t) => t.copyWith(status: TradeStatus.paymentSent),
      );

  @override
  Future<Either<Failure, Trade>> markPaymentReceived(String tradeId) =>
      _transition(
        tradeId,
        (Trade t) => t.copyWith(status: TradeStatus.paymentReceived),
      );

  @override
  Future<Either<Failure, Trade>> releaseEscrow(String tradeId) => _transition(
        tradeId,
        (Trade t) => t.copyWith(
          status: TradeStatus.released,
          releasedAt: DateTime.now(),
        ),
      );

  @override
  Future<Either<Failure, Trade>> cancelTrade(String tradeId) => _transition(
        tradeId,
        (Trade t) => t.copyWith(status: TradeStatus.cancelled),
      );

  @override
  Future<Either<Failure, Trade>> openDispute(String tradeId, String reason) =>
      _transition(
        tradeId,
        (Trade t) => t.copyWith(status: TradeStatus.disputed, disputeReason: reason),
      );

  @override
  Future<Either<Failure, List<TradeMessage>>> messages(String tradeId) async {
    try {
      return Right<Failure, List<TradeMessage>>(await _source.messages(tradeId));
    } catch (e) {
      return Left<Failure, List<TradeMessage>>(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TradeMessage>> sendMessage({
    required String tradeId,
    required String fromUsername,
    required String body,
    bool encrypted = false,
  }) async {
    try {
      final TradeMessage msg = await _source.postMessage(TradeMessage(
        id: '',
        tradeId: tradeId,
        fromUsername: fromUsername,
        body: body,
        sentAt: DateTime.now(),
        encrypted: encrypted,
      ));
      return Right<Failure, TradeMessage>(msg);
    } catch (e) {
      return Left<Failure, TradeMessage>(UnexpectedFailure(e.toString()));
    }
  }
}
