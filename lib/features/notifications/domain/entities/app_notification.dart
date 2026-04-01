import 'package:equatable/equatable.dart';

enum NotificationType { tradeUpdate, newMessage, disputeAlert, systemAlert }

class AppNotification extends Equatable {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String? targetId;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.targetId,
    this.isRead = false,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, type, title, isRead];
}
