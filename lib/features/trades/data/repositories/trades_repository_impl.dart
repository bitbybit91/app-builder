import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/trade.dart';
import '../../domain/entities/trade_message.dart';
import '../../domain/repositories/trades_repository.dart';
import '../datasources/trades_remote_datasource.dart';

class TradesRepositoryImpl implements TradesRepository {
  final TradesRemoteDataSource _remoteDataSource;

  TradesRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<Trade>>> getTrades({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final trades = await _remoteDataSource.getTrades(
        status: status, page: page, limit: limit,
      );
      return Right(trades);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, Trade>> getTradeById(String id) async {
    try {
      final trade = await _remoteDataSource.getTradeById(id);
      return Right(trade);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, Trade>> createTrade({
    required String offerId,
    required double fiatAmount,
  }) async {
    try {
      final trade = await _remoteDataSource.createTrade({
        'offer_id': offerId,
        'fiat_amount': fiatAmount,
      });
      return Right(trade);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> markAsPaid(String tradeId) async {
    try {
      await _remoteDataSource.markAsPaid(tradeId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> releaseTrade(String tradeId) async {
    try {
      await _remoteDataSource.releaseTrade(tradeId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> cancelTrade(String tradeId, {String? reason}) async {
    try {
      await _remoteDataSource.cancelTrade(tradeId, reason);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> disputeTrade(String tradeId, {required String reason}) async {
    try {
      await _remoteDataSource.disputeTrade(tradeId, reason);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, List<TradeMessage>>> getTradeMessages(String tradeId) async {
    try {
      final messages = await _remoteDataSource.getTradeMessages(tradeId);
      return Right(messages);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, TradeMessage>> sendTradeMessage({
    required String tradeId,
    required String content,
    bool encrypt = false,
  }) async {
    try {
      final message = await _remoteDataSource.sendTradeMessage(tradeId, {
        'content': content,
        'encrypt': encrypt,
      });
      return Right(message);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(UnexpectedFailure());
    }
  }
}
