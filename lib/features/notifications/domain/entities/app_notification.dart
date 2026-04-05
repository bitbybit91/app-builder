import 'package:equatable/equatable.dart';

class AppNotification extends Equatable {
  final String id;
  final String type; // TRADE_UPDATE, NEW_MESSAGE, DISPUTE, SYSTEM
  final String title;
  final String body;
  final String? tradeId;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.tradeId,
    this.isRead = false,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, type, isRead];
}
