import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/trade.dart';
import '../services/api_service.dart';

class TradeProvider extends ChangeNotifier {
  List<Trade> _trades = [];
  Trade? _selectedTrade;
  bool _loading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  List<Trade> get trades => _trades;
  Trade? get selectedTrade => _selectedTrade;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  Future<void> fetchTrades({bool refresh = false}) async {
    if (_loading) return;
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _trades = [];
    }
    if (!_hasMore) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final endpoint = '${ApiEndpoints.trades}?page=$_currentPage';
      final response = await ApiService.instance.get(endpoint);
      final data = response as Map<String, dynamic>;
      final items = (data['data'] as List<dynamic>? ?? [])
          .map((e) => Trade.fromJson(e as Map<String, dynamic>))
          .toList();

      _trades.addAll(items);
      final meta = data['meta'] as Map<String, dynamic>?;
      final lastPage = meta?['last_page'] as int? ?? 1;
      _hasMore = _currentPage < lastPage;
      _currentPage++;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTrade(String tradeId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await ApiService.instance.get('${ApiEndpoints.trades}/$tradeId');
      final data = response as Map<String, dynamic>;
      _selectedTrade = Trade.fromJson(data['data'] as Map<String, dynamic>? ?? data);
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Trade?> startTrade(int offerId, double amountFiat) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await ApiService.instance.post(
        ApiEndpoints.trades,
        body: {'offer_id': offerId, 'amount_fiat': amountFiat},
      );
      final data = response as Map<String, dynamic>;
      final trade = Trade.fromJson(data['data'] as Map<String, dynamic>? ?? data);
      _trades.insert(0, trade);
      _selectedTrade = trade;
      return trade;
    } on ApiException catch (e) {
      _error = e.message;
      return null;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> markPaid(String tradeId) async {
    return _postTradeAction('${ApiEndpoints.trades}/$tradeId/paid');
  }

  Future<bool> completeTrade(String tradeId) async {
    return _postTradeAction('${ApiEndpoints.trades}/$tradeId/complete');
  }

  Future<bool> cancelTrade(String tradeId) async {
    return _postTradeAction('${ApiEndpoints.trades}/$tradeId/cancel');
  }

  Future<bool> openDispute(
    String tradeId,
    String reason,
    String details,
  ) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await ApiService.instance.post(
        '${ApiEndpoints.trades}/$tradeId/dispute',
        body: {'reason': reason, 'details': details},
      );
      _refreshTradeFromResponse(response);
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

  Future<bool> sendMessage(String tradeId, String body) async {
    _error = null;
    try {
      await ApiService.instance.post(
        '${ApiEndpoints.trades}/$tradeId/messages',
        body: {'body': body},
      );
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitReview(String tradeId, int rating, String comment) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await ApiService.instance.post(
        '${ApiEndpoints.trades}/$tradeId/reviews',
        body: {'rating': rating, 'comment': comment},
      );
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

  Future<bool> _postTradeAction(String endpoint) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await ApiService.instance.post(endpoint);
      _refreshTradeFromResponse(response);
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

  void _refreshTradeFromResponse(dynamic response) {
    if (response == null) return;
    final data = response as Map<String, dynamic>;
    final tradeData = data['data'] as Map<String, dynamic>? ?? data;
    final updated = Trade.fromJson(tradeData);
    final idx = _trades.indexWhere((t) => t.id == updated.id);
    if (idx != -1) _trades[idx] = updated;
    if (_selectedTrade?.id == updated.id) _selectedTrade = updated;
  }
}
