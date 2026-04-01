import '../entities/wallet.dart';
import '../entities/transaction.dart';

abstract class WalletRepository {
  Future<Wallet> getWallet(String coinType);
  Future<String> generateDepositAddress(String coinType);
  Future<WalletTransaction> withdraw(String coinType, String address, double amount);
  Future<List<WalletTransaction>> getTransactions(String coinType, {int page = 1});
  Future<double> getBalance(String coinType);
}
