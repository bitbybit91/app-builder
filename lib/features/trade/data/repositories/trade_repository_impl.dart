import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:capital_monero/core/errors/failures.dart';
import 'package:capital_monero/core/logging/app_logger.dart';
import 'package:capital_monero/core/network/api_client.dart';
import 'package:capital_monero/features/trade/domain/entities/trade_entity.dart';
import 'package:capital_monero/features/trade/domain/repositories/trade_repository.dart';

@Injectable(as: TradeRepository)
class TradeRepositoryImpl implements TradeRepository {
  static const _tag = 'TradeRepositoryImpl';
  final DioApiClient _apiClient;
  const TradeRepositoryImpl(this._apiClient);

  @override
  Future<Either<Failure, TradeEntity>> getTrade(String id) {
    AppLogger.d(_tag, 'Fetching trade: $id');
    return _apiClient.get<TradeEntity>(
      '/trades/$id',
      fromJson: (json) => TradeEntity.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, List<ChatMessage>>> getMessages(String tradeId) {
    AppLogger.d(_tag, 'Fetching messages for trade: $tradeId');
    return _apiClient.get<List<ChatMessage>>(
      '/trades/$tradeId/messages',
      fromJson: (json) => (json as List<dynamic>)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<Either<Failure, ChatMessage>> sendMessage(String tradeId, String content) {
    AppLogger.d(_tag, 'Sending message for trade: $tradeId');
    return _apiClient.post<ChatMessage>(
      '/trades/$tradeId/messages',
      data: {'content': content},
      fromJson: (json) => ChatMessage.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, TradeEntity>> updateTradeStatus(String tradeId, TradeStatus status) {
    AppLogger.d(_tag, 'Updating trade status: $tradeId -> ${status.name}');
    return _apiClient.put<TradeEntity>(
      '/trades/$tradeId/status',
      data: {'status': status.name},
      fromJson: (json) => TradeEntity.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, void>> openDispute(String tradeId, String reason) async {
    AppLogger.d(_tag, 'Opening dispute for trade: $tradeId');
    final result = await _apiClient.post<void>(
      '/trades/$tradeId/dispute',
      data: {'reason': reason},
    );
    return result.map((_) => null);
  }
}
