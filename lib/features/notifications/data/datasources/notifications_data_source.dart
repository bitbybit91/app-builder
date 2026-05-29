import 'package:uuid/uuid.dart';

import '../../domain/entities/app_notification.dart';

abstract class NotificationsDataSource {
  Future<List<AppNotification>> list();
  Future<void> markAllRead();
  Future<void> markRead(String id);
  Future<void> registerPushToken(String token);
}

class InMemoryNotificationsDataSource implements NotificationsDataSource {
  InMemoryNotificationsDataSource() {
    _seed();
  }

  final Uuid _uuid = const Uuid();
  final List<AppNotification> _items = <AppNotification>[];

  void _seed() {
    final DateTime now = DateTime.now();
    _items.addAll(<AppNotification>[
      AppNotification(
        id: _uuid.v4(),
        title: 'Trade #a31 funded',
        body: 'Seller satoshi has funded the escrow.',
        createdAt: now.subtract(const Duration(minutes: 10)),
        kind: NotificationKind.tradeUpdate,
      ),
      AppNotification(
        id: _uuid.v4(),
        title: 'New message from alice',
        body: '"I can do SEPA tomorrow at 09:00 CET."',
        createdAt: now.subtract(const Duration(hours: 2)),
        kind: NotificationKind.newMessage,
        deeplink: '/messages/alice',
      ),
      AppNotification(
        id: _uuid.v4(),
        title: 'Welcome to CapitalMonero',
        body: 'Take a moment to enable 2FA for your account.',
        createdAt: now.subtract(const Duration(days: 1)),
        kind: NotificationKind.system,
        deeplink: '/2fa-setup',
      ),
    ]);
  }

  @override
  Future<List<AppNotification>> list() async => List<AppNotification>.from(_items)
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<void> markAllRead() async {
    for (int i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(read: true);
    }
  }

  @override
  Future<void> markRead(String id) async {
    final int idx = _items.indexWhere((n) => n.id == id);
    if (idx >= 0) _items[idx] = _items[idx].copyWith(read: true);
  }

  @override
  Future<void> registerPushToken(String token) async {
    // In production this would POST the FCM token to the backend.
  }
}
