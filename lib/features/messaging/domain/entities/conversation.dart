import 'package:equatable/equatable.dart';

class Conversation extends Equatable {
  final String id;
  final String participantId;
  final String participantUsername;
  final String? tradeId;
  final String? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;

  const Conversation({
    required this.id,
    required this.participantId,
    required this.participantUsername,
    this.tradeId,
    this.lastMessage,
    this.unreadCount = 0,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, participantId, unreadCount];
}
