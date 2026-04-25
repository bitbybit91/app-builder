import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:capital_monero/core/errors/failures.dart';
import 'package:capital_monero/core/logging/app_logger.dart';
import 'package:capital_monero/core/network/api_client.dart';
import 'package:capital_monero/features/trading/domain/entities/create_offer_params.dart';
import 'package:capital_monero/features/trading/domain/entities/offer_entity.dart';
import 'package:capital_monero/features/trading/domain/repositories/trading_repository.dart';

@Injectable(as: TradingRepository)
class TradingRepositoryImpl implements TradingRepository {
  static const _tag = 'TradingRepositoryImpl';

  final DioApiClient _apiClient;

  const TradingRepositoryImpl(this._apiClient);

  @override
  Future<Either<Failure, List<OfferEntity>>> getOffers({
    String? currency,
    String? fiatCurrency,
    OfferType? type,
    String? paymentMethod,
  }) async {
    final queryParams = <String, dynamic>{
      if (currency != null) 'currency': currency,
      if (fiatCurrency != null) 'fiat_currency': fiatCurrency,
      if (type != null) 'type': type.name,
      if (paymentMethod != null) 'payment_method': paymentMethod,
    };

    AppLogger.d(_tag, 'Fetching offers with params: $queryParams');

    return _apiClient.get<List<OfferEntity>>(
      '/offers',
      queryParameters: queryParams,
      fromJson: (json) => (json as List<dynamic>)
          .map((e) => OfferEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<Either<Failure, OfferEntity>> getOffer(String id) {
    AppLogger.d(_tag, 'Fetching offer: $id');
    return _apiClient.get<OfferEntity>(
      '/offers/$id',
      fromJson: (json) => OfferEntity.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, OfferEntity>> createOffer(
    CreateOfferParams params,
  ) {
    AppLogger.d(_tag, 'Creating offer');
    return _apiClient.post<OfferEntity>(
      '/offers',
      data: params.toJson(),
      fromJson: (json) => OfferEntity.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, void>> cancelOffer(String id) async {
    AppLogger.d(_tag, 'Cancelling offer: $id');
    final result = await _apiClient.delete<void>('/offers/$id');
    return result.map((_) => null);
  }
}
