import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/offer_model.dart';
import '../models/trade_model.dart';
import '../../domain/entities/offer.dart';
import '../../domain/entities/trade.dart';

class TradingRemoteDataSource {
  final ApiClient _apiClient;
  TradingRemoteDataSource(this._apiClient);

  Future<List<OfferModel>> getOffers({String? coinType, OfferType? offerType, String? currency, int page = 1}) async {
    try {
      final queryParams = <String, dynamic>{'page': page};
      if (coinType != null) queryParams['coin_type'] = coinType;
      if (offerType != null) queryParams['offer_type'] = offerType.name;
      if (currency != null) queryParams['currency'] = currency;
      final response = await _apiClient.get(ApiEndpoints.offers, queryParameters: queryParams);
      final list = (response.data['data'] as List<dynamic>?) ?? [];
      return list.map((json) => OfferModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ServerException(message: 'Failed to fetch offers: ${e.toString()}');
    }
  }

  Future<OfferModel> getOffer(String id) async {
    try {
      final response = await _apiClient.get('${ApiEndpoints.offers}/$id');
      return OfferModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException(message: 'Failed to fetch offer: ${e.toString()}');
    }
  }

  Future<OfferModel> createOffer(Map<String, dynamic> offerData) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.offers, data: offerData);
      return OfferModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException(message: 'Failed to create offer: ${e.toString()}');
    }
  }

  Future<TradeModel> initiateTrade(String offerId, double amount) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.trades, data: {
        'offer_id': offerId,
        'amount': amount,
      });
      return TradeModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException(message: 'Failed to initiate trade: ${e.toString()}');
    }
  }

  Future<TradeModel> getTrade(String id) async {
    try {
      final response = await _apiClient.get('${ApiEndpoints.trades}/$id');
      return TradeModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException(message: 'Failed to fetch trade: ${e.toString()}');
    }
  }

  Future<List<TradeModel>> getTrades({TradeStatus? status, int page = 1}) async {
    try {
      final queryParams = <String, dynamic>{'page': page};
      if (status != null) queryParams['status'] = status.name;
      final response = await _apiClient.get(ApiEndpoints.trades, queryParameters: queryParams);
      final list = (response.data['data'] as List<dynamic>?) ?? [];
      return list.map((json) => TradeModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ServerException(message: 'Failed to fetch trades: ${e.toString()}');
    }
  }

  Future<TradeModel> updateTradeStatus(String tradeId, TradeStatus status) async {
    try {
      final response = await _apiClient.patch('${ApiEndpoints.trades}/$tradeId', data: {'status': status.name});
      return TradeModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException(message: 'Failed to update trade: ${e.toString()}');
    }
  }
}
