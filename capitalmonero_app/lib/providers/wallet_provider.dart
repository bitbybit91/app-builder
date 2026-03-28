import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../config/constants.dart';
import '../models/swap.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../services/api_service.dart';

class WalletProvider extends ChangeNotifier {
  List<Wallet> _wallets = [];
  List<Transaction> _transactions = [];
  List<Swap> _swaps = [];
  bool _loading = false;
  String? _error;
  int _transactionPage = 1;
  bool _hasMoreTransactions = true;

  List<Wallet> get wallets => _wallets;
  List<Transaction> get transactions => _transactions;
  List<Swap> get swaps => _swaps;
  bool get loading => _loading;
  String? get error => _error;

  Wallet? get btcWallet =>
      _wallets.where((w) => w.crypto == CryptoCurrencies.btc).firstOrNull;

  Wallet? get xmrWallet =>
      _wallets.where((w) => w.crypto == CryptoCurrencies.xmr).firstOrNull;

  Future<void> fetchWallets() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await ApiService.instance.get(ApiEndpoints.wallets);
      final data = response as Map<String, dynamic>;
      final list = data['data'] as List<dynamic>? ?? (response as List<dynamic>? ?? []);
      _wallets = list
          .map((e) => Wallet.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTransactions({String? crypto, bool refresh = false}) async {
    if (_loading) return;
    if (refresh) {
      _transactionPage = 1;
      _hasMoreTransactions = true;
      _transactions = [];
    }
    if (!_hasMoreTransactions) return;

    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final queryParams = <String, String>{'page': _transactionPage.toString()};
      if (crypto != null) queryParams['crypto'] = crypto;
      final query = Uri(queryParameters: queryParams).query;
      final response = await ApiService.instance.get('${ApiEndpoints.transactions}?$query');
      final data = response as Map<String, dynamic>;
      final items = (data['data'] as List<dynamic>? ?? [])
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList();
      _transactions.addAll(items);
      final meta = data['meta'] as Map<String, dynamic>?;
      final lastPage = meta?['last_page'] as int? ?? 1;
      _hasMoreTransactions = _transactionPage < lastPage;
      _transactionPage++;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> withdraw(String crypto, String address, double amount) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await ApiService.instance.post(
        ApiEndpoints.withdraw,
        body: {'crypto': crypto, 'address': address, 'amount': amount},
      );
      await fetchWallets();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> swap(String fromCrypto, String toCrypto, double amount) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await ApiService.instance.post(
        ApiEndpoints.swap,
        body: {
          'from_crypto': fromCrypto,
          'to_crypto': toCrypto,
          'amount': amount,
        },
      );
      final data = response as Map<String, dynamic>;
      final newSwap = Swap.fromJson(data['data'] as Map<String, dynamic>? ?? data);
      _swaps.insert(0, newSwap);
      await fetchWallets();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSwapHistory() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await ApiService.instance.get(ApiEndpoints.swapHistory);
      final data = response as Map<String, dynamic>;
      final list = data['data'] as List<dynamic>? ?? (response as List<dynamic>? ?? []);
      _swaps = list
          .map((e) => Swap.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
