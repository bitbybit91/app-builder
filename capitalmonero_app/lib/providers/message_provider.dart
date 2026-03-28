import 'dart:async';

import 'package:flutter/material.dart';

import '../models/message.dart';
import '../models/trade.dart';
import '../services/api_service.dart';

class MessageProvider extends ChangeNotifier {
  List<Message> _messages = [];
  String? _currentTradeId;
  bool _loading = false;
  String? _error;
  Timer? _pollingTimer;

  List<Message> get messages => _messages;
  String? get currentTradeId => _currentTradeId;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchMessages(String tradeId) async {
    _error = null;
    try {
      final response = await ApiService.instance.get('/trades/$tradeId');
      final data = response as Map<String, dynamic>;
      final tradeData = data['data'] as Map<String, dynamic>? ?? data;
      final trade = Trade.fromJson(tradeData);
      _messages = trade.messages;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> sendMessage(String tradeId, String body) async {
    _error = null;
    try {
      final response = await ApiService.instance.post(
        '/trades/$tradeId/messages',
        body: {'body': body},
      );
      final data = response as Map<String, dynamic>;
      final msgData = data['data'] as Map<String, dynamic>? ?? data;
      final message = Message.fromJson(msgData);
      _messages.add(message);
      notifyListeners();
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

  void startPolling(String tradeId) {
    _currentTradeId = tradeId;
    stopPolling();
    fetchMessages(tradeId);
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      fetchMessages(tradeId);
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void clearMessages() {
    _messages = [];
    _currentTradeId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
