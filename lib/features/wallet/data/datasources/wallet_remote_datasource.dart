import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';

class WalletRemoteDataSource {
  final ApiClient _apiClient;
  WalletRemoteDataSource(this._apiClient);

  Future<WalletModel> getWallet(String coinType) async {
    try {
      final response = await _apiClient.get('${ApiEndpoints.walletBalance}/$coinType');
      return WalletModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException(message: 'Failed to fetch wallet: ${e.toString()}');
    }
  }

  Future<String> generateDepositAddress(String coinType) async {
    try {
      final response = await _apiClient.post('${ApiEndpoints.walletDeposit}/$coinType');
      return (response.data as Map<String, dynamic>)['address'] as String;
    } catch (e) {
      throw ServerException(message: 'Failed to generate address: ${e.toString()}');
    }
  }

  Future<TransactionModel> withdraw(String coinType, String address, double amount) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.walletWithdraw,
        data: {'coin_type': coinType, 'address': address, 'amount': amount},
      );
      return TransactionModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException(message: 'Withdrawal failed: ${e.toString()}');
    }
  }

  Future<List<TransactionModel>> getTransactions(String coinType, {int page = 1}) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.walletTransactions}/$coinType',
        queryParameters: {'page': page},
      );
      final list = (response.data['data'] as List<dynamic>?) ?? [];
      return list.map((json) => TransactionModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ServerException(message: 'Failed to fetch transactions: ${e.toString()}');
    }
  }
}
