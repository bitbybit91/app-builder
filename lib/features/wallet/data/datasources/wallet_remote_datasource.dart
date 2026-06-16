import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/wallet_balance_model.dart';
import '../models/wallet_transaction_model.dart';

abstract class WalletRemoteDataSource {
  Future<List<WalletBalanceModel>> getBalances();
  Future<String> getDepositAddress(String currency);
  Future<void> withdraw({
    required String currency,
    required String address,
    required double amount,
  });
  Future<List<WalletTransactionModel>> getTransactions({
    String? currency,
    String? type,
    int page = 1,
    int limit = 20,
  });
}

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  final ApiClient _apiClient;

  WalletRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<WalletBalanceModel>> getBalances() async {
    try {
      final response = await _apiClient.get(ApiConstants.walletBalances);
      final data = response.data as Map<String, dynamic>;
      final items = data['data'] as List;
      return items.map((e) => WalletBalanceModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw const ServerException(message: 'Failed to load wallet balances');
    }
  }

  @override
  Future<String> getDepositAddress(String currency) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.walletDeposit,
        data: {'currency': currency},
      );
      final data = response.data as Map<String, dynamic>;
      return data['address'] as String;
    } catch (e) {
      throw const ServerException(message: 'Failed to generate deposit address');
    }
  }

  @override
  Future<void> withdraw({
    required String currency,
    required String address,
    required double amount,
  }) async {
    try {
      await _apiClient.post(
        ApiConstants.walletWithdraw,
        data: {
          'currency': currency,
          'address': address,
          'amount': amount,
        },
      );
    } catch (e) {
      throw const ServerException(message: 'Withdrawal failed');
    }
  }

  @override
  Future<List<WalletTransactionModel>> getTransactions({
    String? currency,
    String? type,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.walletTransactions,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (currency != null) 'currency': currency,
          if (type != null) 'type': type,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final items = data['data'] as List;
      return items
          .map((e) => WalletTransactionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw const ServerException(message: 'Failed to load transactions');
    }
  }
}
