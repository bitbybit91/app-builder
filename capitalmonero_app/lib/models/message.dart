import 'user.dart';

class Message {
  final int id;
  final int senderId;
  final int? receiverId;
  final int? tradeId;
  final String body;
  final bool isRead;
  final DateTime? readAt;
  final User? sender;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.senderId,
    this.receiverId,
    this.tradeId,
    required this.body,
    required this.isRead,
    this.readAt,
    this.sender,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as int,
      senderId: json['sender_id'] as int,
      receiverId: json['receiver_id'] as int?,
      tradeId: json['trade_id'] as int?,
      body: json['body'] as String,
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      sender: json['sender'] != null
          ? User.fromJson(json['sender'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'trade_id': tradeId,
      'body': body,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'sender': sender?.toJson(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  Message copyWith({
    int? id,
    int? senderId,
    int? receiverId,
    int? tradeId,
    String? body,
    bool? isRead,
    DateTime? readAt,
    User? sender,
    DateTime? createdAt,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      tradeId: tradeId ?? this.tradeId,
      body: body ?? this.body,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      sender: sender ?? this.sender,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Message(id: $id, senderId: $senderId)';
}
