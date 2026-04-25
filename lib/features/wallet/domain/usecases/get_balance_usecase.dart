import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:capital_monero/core/errors/failures.dart';
import 'package:capital_monero/features/wallet/domain/entities/wallet_entity.dart';
import 'package:capital_monero/features/wallet/domain/repositories/wallet_repository.dart';

@injectable
class GetBalanceUseCase {
  final WalletRepository _repository;

  const GetBalanceUseCase(this._repository);

  Future<Either<Failure, BalanceEntity>> call(CryptoCurrency currency) =>
      _repository.getBalance(currency);
}
