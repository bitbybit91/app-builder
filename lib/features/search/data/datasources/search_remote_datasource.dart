import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../trading/data/models/offer_model.dart';
import '../../domain/entities/search_filter.dart';

class SearchRemoteDataSource {
  final ApiClient _apiClient;
  SearchRemoteDataSource(this._apiClient);

  Future<List<OfferModel>> searchOffers(SearchFilter filter) async {
    try {
      final queryParams = <String, dynamic>{'page': filter.page};
      if (filter.coinType != null) queryParams['coin_type'] = filter.coinType;
      if (filter.offerType != null) queryParams['offer_type'] = filter.offerType;
      if (filter.paymentMethod != null) queryParams['payment_method'] = filter.paymentMethod;
      if (filter.currency != null) queryParams['currency'] = filter.currency;
      if (filter.country != null) queryParams['country'] = filter.country;
      if (filter.sortBy != null) queryParams['sort_by'] = filter.sortBy;
      final response = await _apiClient.get(ApiEndpoints.search, queryParameters: queryParams);
      final list = (response.data['data'] as List<dynamic>?) ?? [];
      return list.map((json) => OfferModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ServerException(message: 'Search failed: ${e.toString()}');
    }
  }
}
