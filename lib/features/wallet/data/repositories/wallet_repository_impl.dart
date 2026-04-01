import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_datasource.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDataSource _remoteDataSource;
  WalletRepositoryImpl(this._remoteDataSource);

  @override
  Future<Wallet> getWallet(String coinType) async {
    try {
      return await _remoteDataSource.getWallet(coinType);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<String> generateDepositAddress(String coinType) async {
    try {
      return await _remoteDataSource.generateDepositAddress(coinType);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<WalletTransaction> withdraw(String coinType, String address, double amount) async {
    try {
      return await _remoteDataSource.withdraw(coinType, address, amount);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<List<WalletTransaction>> getTransactions(String coinType, {int page = 1}) async {
    try {
      return await _remoteDataSource.getTransactions(coinType, page: page);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<double> getBalance(String coinType) async {
    try {
      final wallet = await _remoteDataSource.getWallet(coinType);
      return wallet.balance;
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }
}
