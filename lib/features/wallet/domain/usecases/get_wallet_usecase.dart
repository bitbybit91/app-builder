import '../entities/wallet.dart';
import '../repositories/wallet_repository.dart';

class GetWalletUseCase {
  final WalletRepository _repository;
  GetWalletUseCase(this._repository);

  Future<Wallet> call(String coinType) {
    return _repository.getWallet(coinType);
  }
}
