import 'package:equatable/equatable.dart';

class Conversation extends Equatable {
  const Conversation({
    required this.peerUsername,
    required this.lastMessage,
    required this.updatedAt,
    this.unreadCount = 0,
  });
  final String peerUsername;
  final String lastMessage;
  final DateTime updatedAt;
  final int unreadCount;

  @override
  List<Object?> get props =>
      <Object?>[peerUsername, lastMessage, updatedAt, unreadCount];
}

class DirectMessage extends Equatable {
  const DirectMessage({
    required this.id,
    required this.fromUsername,
    required this.toUsername,
    required this.body,
    required this.sentAt,
    this.encrypted = false,
  });
  final String id;
  final String fromUsername;
  final String toUsername;
  final String body;
  final DateTime sentAt;
  final bool encrypted;

  @override
  List<Object?> get props =>
      <Object?>[id, fromUsername, toUsername, body, sentAt, encrypted];
}
