import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/wallet_balance.dart';
import '../repositories/wallet_repository.dart';

class GetWalletBalancesUseCase extends UseCase<List<WalletBalance>, NoParams> {
  final WalletRepository repository;

  GetWalletBalancesUseCase(this.repository);

  @override
  Future<Either<Failure, List<WalletBalance>>> call(NoParams params) {
    return repository.getBalances();
  }
}
