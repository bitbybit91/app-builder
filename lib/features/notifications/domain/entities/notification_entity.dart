import 'package:equatable/equatable.dart';

enum NotificationType { tradeUpdate, message, offer, system }

class NotificationEntity extends Equatable {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String? tradeId;
  final DateTime createdAt;
  final bool isRead;

  const NotificationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.tradeId,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationEntity.fromJson(Map<String, dynamic> json) => NotificationEntity(
        id: json['id'] as String,
        type: NotificationType.values.byName(json['type'] as String),
        title: json['title'] as String,
        body: json['body'] as String,
        tradeId: json['trade_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        isRead: json['is_read'] as bool? ?? false,
      );

  NotificationEntity copyWith({
    String? id, NotificationType? type, String? title, String? body,
    String? tradeId, DateTime? createdAt, bool? isRead,
  }) =>
      NotificationEntity(
        id: id ?? this.id, type: type ?? this.type, title: title ?? this.title,
        body: body ?? this.body, tradeId: tradeId ?? this.tradeId,
        createdAt: createdAt ?? this.createdAt, isRead: isRead ?? this.isRead,
      );

  @override
  List<Object?> get props => [id, type, title, body, tradeId, createdAt, isRead];
  @override bool get stringify => true;
}
