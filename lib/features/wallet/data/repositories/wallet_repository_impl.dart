import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/wallet_balance.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_datasource.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDataSource _remoteDataSource;

  WalletRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<WalletBalance>>> getBalances() async {
    try {
      final balances = await _remoteDataSource.getBalances();
      return Right(balances);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, String>> getDepositAddress(String currency) async {
    try {
      final address = await _remoteDataSource.getDepositAddress(currency);
      return Right(address);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> withdraw({
    required String currency,
    required String address,
    required double amount,
  }) async {
    try {
      await _remoteDataSource.withdraw(
        currency: currency,
        address: address,
        amount: amount,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, List<WalletTransaction>>> getTransactions({
    String? currency,
    String? type,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final txs = await _remoteDataSource.getTransactions(
        currency: currency,
        type: type,
        page: page,
        limit: limit,
      );
      return Right(txs);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(UnexpectedFailure());
    }
  }
}
