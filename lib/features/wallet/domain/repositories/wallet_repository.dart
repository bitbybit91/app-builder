import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/wallet_balance.dart';

abstract class WalletRepository {
  Future<Either<Failure, WalletBalance>> getBalance(String coin);
  Future<Either<Failure, String>> generateDepositAddress(String coin);
  Future<Either<Failure, WalletTransaction>> withdraw({
    required String coin,
    required String destination,
    required double amount,
  });
  Future<Either<Failure, List<WalletTransaction>>> history(String coin);
}
