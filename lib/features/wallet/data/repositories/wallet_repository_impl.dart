import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/wallet_balance.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_data_source.dart';

class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl({required WalletDataSource source}) : _source = source;
  final WalletDataSource _source;

  @override
  Future<Either<Failure, WalletBalance>> getBalance(String coin) async {
    try {
      return Right<Failure, WalletBalance>(await _source.balance(coin));
    } on WalletException catch (e) {
      return Left<Failure, WalletBalance>(WalletFailure(e.message));
    } catch (e) {
      return Left<Failure, WalletBalance>(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> generateDepositAddress(String coin) async {
    try {
      return Right<Failure, String>(await _source.newDepositAddress(coin));
    } on WalletException catch (e) {
      return Left<Failure, String>(WalletFailure(e.message));
    } catch (e) {
      return Left<Failure, String>(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, WalletTransaction>> withdraw({
    required String coin,
    required String destination,
    required double amount,
  }) async {
    try {
      return Right<Failure, WalletTransaction>(
        await _source.withdraw(
          coin: coin,
          destination: destination,
          amount: amount,
        ),
      );
    } on WalletException catch (e) {
      return Left<Failure, WalletTransaction>(WalletFailure(e.message));
    } on ValidationException catch (e) {
      return Left<Failure, WalletTransaction>(ValidationFailure(e.message));
    } catch (e) {
      return Left<Failure, WalletTransaction>(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<WalletTransaction>>> history(String coin) async {
    try {
      return Right<Failure, List<WalletTransaction>>(
          await _source.history(coin));
    } catch (e) {
      return Left<Failure, List<WalletTransaction>>(
          UnexpectedFailure(e.toString()));
    }
  }
}
