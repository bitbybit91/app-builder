import 'package:equatable/equatable.dart';

class TradeMessage extends Equatable {
  final String id;
  final String tradeId;
  final String senderUsername;
  final String content;
  final bool isEncrypted;
  final bool isSystemMessage;
  final DateTime createdAt;

  const TradeMessage({
    required this.id,
    required this.tradeId,
    required this.senderUsername,
    required this.content,
    this.isEncrypted = false,
    this.isSystemMessage = false,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, tradeId, createdAt];
}
