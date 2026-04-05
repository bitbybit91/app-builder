import '../../domain/entities/trade_message.dart';

class TradeMessageModel extends TradeMessage {
  const TradeMessageModel({
    required super.id,
    required super.tradeId,
    required super.senderUsername,
    required super.content,
    super.isEncrypted,
    super.isSystemMessage,
    required super.createdAt,
  });

  factory TradeMessageModel.fromJson(Map<String, dynamic> json) {
    return TradeMessageModel(
      id: json['id'] as String,
      tradeId: json['trade_id'] as String,
      senderUsername: json['sender_username'] as String,
      content: json['content'] as String,
      isEncrypted: json['is_encrypted'] as bool? ?? false,
      isSystemMessage: json['is_system_message'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trade_id': tradeId,
      'sender_username': senderUsername,
      'content': content,
      'is_encrypted': isEncrypted,
      'is_system_message': isSystemMessage,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
