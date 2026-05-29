import 'package:equatable/equatable.dart';

enum NotificationKind { tradeUpdate, newMessage, disputeAlert, system }

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.kind,
    this.read = false,
    this.deeplink,
  });
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final NotificationKind kind;
  final bool read;
  final String? deeplink;

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        title: title,
        body: body,
        createdAt: createdAt,
        kind: kind,
        read: read ?? this.read,
        deeplink: deeplink,
      );

  @override
  List<Object?> get props => <Object?>[id, title, body, createdAt, kind, read, deeplink];
}
