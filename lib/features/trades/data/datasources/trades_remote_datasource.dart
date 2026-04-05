import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/trade_model.dart';
import '../models/trade_message_model.dart';

abstract class TradesRemoteDataSource {
  Future<List<TradeModel>> getTrades({String? status, int page = 1, int limit = 20});
  Future<TradeModel> getTradeById(String id);
  Future<TradeModel> createTrade(Map<String, dynamic> data);
  Future<void> markAsPaid(String tradeId);
  Future<void> releaseTrade(String tradeId);
  Future<void> cancelTrade(String tradeId, String? reason);
  Future<void> disputeTrade(String tradeId, String reason);
  Future<List<TradeMessageModel>> getTradeMessages(String tradeId);
  Future<TradeMessageModel> sendTradeMessage(String tradeId, Map<String, dynamic> data);
}

class TradesRemoteDataSourceImpl implements TradesRemoteDataSource {
  final ApiClient _apiClient;

  TradesRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<TradeModel>> getTrades({String? status, int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.trades,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (status != null) 'status': status,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final items = data['data'] as List;
      return items.map((e) => TradeModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw const ServerException(message: 'Failed to load trades');
    }
  }

  @override
  Future<TradeModel> getTradeById(String id) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.tradeDetail.replaceFirst('{id}', id),
      );
      return TradeModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw const ServerException(message: 'Failed to load trade');
    }
  }

  @override
  Future<TradeModel> createTrade(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(ApiConstants.trades, data: data);
      return TradeModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw const ServerException(message: 'Failed to create trade');
    }
  }

  @override
  Future<void> markAsPaid(String tradeId) async {
    try {
      await _apiClient.post(
        '${ApiConstants.tradeDetail.replaceFirst('{id}', tradeId)}/paid',
      );
    } catch (e) {
      throw const ServerException(message: 'Failed to mark trade as paid');
    }
  }

  @override
  Future<void> releaseTrade(String tradeId) async {
    try {
      await _apiClient.post(ApiConstants.tradeRelease.replaceFirst('{id}', tradeId));
    } catch (e) {
      throw const ServerException(message: 'Failed to release trade');
    }
  }

  @override
  Future<void> cancelTrade(String tradeId, String? reason) async {
    try {
      await _apiClient.post(
        ApiConstants.tradeCancel.replaceFirst('{id}', tradeId),
        data: {if (reason != null) 'reason': reason},
      );
    } catch (e) {
      throw const ServerException(message: 'Failed to cancel trade');
    }
  }

  @override
  Future<void> disputeTrade(String tradeId, String reason) async {
    try {
      await _apiClient.post(
        ApiConstants.tradeDispute.replaceFirst('{id}', tradeId),
        data: {'reason': reason},
      );
    } catch (e) {
      throw const ServerException(message: 'Failed to dispute trade');
    }
  }

  @override
  Future<List<TradeMessageModel>> getTradeMessages(String tradeId) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.tradeChat.replaceFirst('{id}', tradeId),
      );
      final data = response.data as Map<String, dynamic>;
      final items = data['data'] as List;
      return items.map((e) => TradeMessageModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw const ServerException(message: 'Failed to load messages');
    }
  }

  @override
  Future<TradeMessageModel> sendTradeMessage(String tradeId, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.tradeChat.replaceFirst('{id}', tradeId),
        data: data,
      );
      return TradeMessageModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw const ServerException(message: 'Failed to send message');
    }
  }
}
