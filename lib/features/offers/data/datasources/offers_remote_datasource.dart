import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/offer_model.dart';

abstract class OffersRemoteDataSource {
  Future<List<OfferModel>> getOffers({
    String? tradeType,
    String? cryptoCurrency,
    String? fiatCurrency,
    String? paymentMethod,
    String? countryCode,
    int page = 1,
    int limit = 20,
  });

  Future<OfferModel> getOfferById(String id);

  Future<OfferModel> createOffer(Map<String, dynamic> data);

  Future<OfferModel> updateOffer(String id, Map<String, dynamic> data);

  Future<void> deleteOffer(String id);

  Future<List<OfferModel>> getMyOffers();
}

class OffersRemoteDataSourceImpl implements OffersRemoteDataSource {
  final ApiClient _apiClient;

  OffersRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<OfferModel>> getOffers({
    String? tradeType,
    String? cryptoCurrency,
    String? fiatCurrency,
    String? paymentMethod,
    String? countryCode,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (tradeType != null) 'trade_type': tradeType,
        if (cryptoCurrency != null) 'crypto_currency': cryptoCurrency,
        if (fiatCurrency != null) 'fiat_currency': fiatCurrency,
        if (paymentMethod != null) 'payment_method': paymentMethod,
        if (countryCode != null) 'country_code': countryCode,
      };
      final response = await _apiClient.get(
        ApiConstants.offers,
        queryParameters: queryParams,
      );
      final data = response.data as Map<String, dynamic>;
      final items = data['data'] as List;
      return items
          .map((e) => OfferModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw const ServerException(message: 'Failed to load offers');
    }
  }

  @override
  Future<OfferModel> getOfferById(String id) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.offerDetail.replaceFirst('{id}', id),
      );
      return OfferModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw const ServerException(message: 'Failed to load offer');
    }
  }

  @override
  Future<OfferModel> createOffer(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.offers,
        data: data,
      );
      return OfferModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw const ServerException(message: 'Failed to create offer');
    }
  }

  @override
  Future<OfferModel> updateOffer(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(
        ApiConstants.offerDetail.replaceFirst('{id}', id),
        data: data,
      );
      return OfferModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw const ServerException(message: 'Failed to update offer');
    }
  }

  @override
  Future<void> deleteOffer(String id) async {
    try {
      await _apiClient.delete(
        ApiConstants.offerDetail.replaceFirst('{id}', id),
      );
    } catch (e) {
      throw const ServerException(message: 'Failed to delete offer');
    }
  }

  @override
  Future<List<OfferModel>> getMyOffers() async {
    try {
      final response = await _apiClient.get(ApiConstants.myOffers);
      final data = response.data as Map<String, dynamic>;
      final items = data['data'] as List;
      return items
          .map((e) => OfferModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw const ServerException(message: 'Failed to load your offers');
    }
  }
}
