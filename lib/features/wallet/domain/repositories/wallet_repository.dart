import 'package:dartz/dartz.dart';

import 'package:capital_monero/core/errors/failures.dart';
import 'package:capital_monero/features/wallet/domain/entities/wallet_entity.dart';

abstract interface class WalletRepository {
  Future<Either<Failure, String>> getWalletAddress(CryptoCurrency currency);

  Future<Either<Failure, BalanceEntity>> getBalance(CryptoCurrency currency);

  Future<Either<Failure, String>> sendTransaction(
    CryptoCurrency currency,
    String toAddress,
    String amount, [
    String? fee,
  ]);
}
