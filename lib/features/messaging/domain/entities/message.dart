import 'package:equatable/equatable.dart';

class Message extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderUsername;
  final String content;
  final bool isEncrypted;
  final bool isRead;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderUsername,
    required this.content,
    this.isEncrypted = false,
    this.isRead = false,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, conversationId, senderId, content];
}
