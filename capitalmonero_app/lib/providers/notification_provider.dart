import 'dart:async';

import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/app_notification.dart';
import '../services/api_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _loading = false;
  Timer? _pollingTimer;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get loading => _loading;

  Future<void> fetchNotifications() async {
    _loading = true;
    notifyListeners();
    try {
      final response = await ApiService.instance.get(ApiEndpoints.notifications);
      final data = response as Map<String, dynamic>;
      final list = data['data'] as List<dynamic>? ?? (response as List<dynamic>? ?? []);
      _notifications = list
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
      _unreadCount = _notifications.where((n) => !n.isRead).length;
    } on ApiException {
      // Silently fail on background polling
    } catch (_) {
      // Silently fail on background polling
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await ApiService.instance.post(ApiEndpoints.markNotificationRead(id));
      final idx = _notifications.indexWhere((n) => n.id == id);
      if (idx != -1) {
        final updated = AppNotification(
          id: _notifications[idx].id,
          userId: _notifications[idx].userId,
          type: _notifications[idx].type,
          title: _notifications[idx].title,
          message: _notifications[idx].message,
          data: _notifications[idx].data,
          isRead: true,
          readAt: DateTime.now(),
          createdAt: _notifications[idx].createdAt,
        );
        _notifications[idx] = updated;
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        notifyListeners();
      }
    } on ApiException {
      // Non-critical, ignore
    } catch (_) {
      // Non-critical, ignore
    }
  }

  void startPolling() {
    stopPolling();
    fetchNotifications();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      fetchNotifications();
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
