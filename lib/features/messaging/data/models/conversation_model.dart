import '../../domain/entities/conversation.dart';

class ConversationModel extends Conversation {
  const ConversationModel({
    required super.id,
    required super.participantId,
    required super.participantUsername,
    super.tradeId,
    super.lastMessage,
    super.unreadCount,
    required super.updatedAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      participantId: json['participant_id'] as String,
      participantUsername: json['participant_username'] as String,
      tradeId: json['trade_id'] as String?,
      lastMessage: json['last_message'] as String?,
      unreadCount: json['unread_count'] as int? ?? 0,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participant_id': participantId,
      'participant_username': participantUsername,
      'trade_id': tradeId,
      'last_message': lastMessage,
      'unread_count': unreadCount,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
