import '../../domain/entities/app_notification.dart';

class NotificationModel extends AppNotification {
  const NotificationModel({
    required super.id,
    required super.type,
    required super.title,
    required super.body,
    super.targetId,
    super.isRead,
    required super.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      type: NotificationType.values.byName(json['type'] as String),
      title: json['title'] as String,
      body: json['body'] as String,
      targetId: json['target_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id, 'type': type.name, 'title': title,
      'body': body, 'target_id': targetId,
      'is_read': isRead, 'created_at': createdAt.toIso8601String(),
    };
  }
}
