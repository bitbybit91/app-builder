import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/wallet_balance.dart';
import '../entities/wallet_transaction.dart';

abstract class WalletRepository {
  Future<Either<Failure, List<WalletBalance>>> getBalances();
  Future<Either<Failure, String>> getDepositAddress(String currency);
  Future<Either<Failure, void>> withdraw({
    required String currency,
    required String address,
    required double amount,
  });
  Future<Either<Failure, List<WalletTransaction>>> getTransactions({
    String? currency,
    String? type,
    int page = 1,
    int limit = 20,
  });
}
