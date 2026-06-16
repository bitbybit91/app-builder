import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/di/injection.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../domain/entities/app_notification.dart';
import '../bloc/notifications_bloc.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  IconData _iconForType(String type) {
    switch (type) {
      case 'TRADE_UPDATE':
        return Icons.swap_horiz;
      case 'NEW_MESSAGE':
        return Icons.message;
      case 'DISPUTE':
        return Icons.warning;
      case 'SYSTEM':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<NotificationsBloc>()..add(const NotificationsLoadRequested()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          actions: [
            BlocBuilder<NotificationsBloc, NotificationsState>(
              builder: (context, state) {
                return IconButton(
                  icon: const Icon(Icons.done_all),
                  onPressed: () {
                    context.read<NotificationsBloc>().add(
                          const NotificationsMarkAllReadRequested(),
                        );
                  },
                  tooltip: 'Mark all as read',
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<NotificationsBloc, NotificationsState>(
          builder: (context, state) {
            if (state is NotificationsLoading) {
              return const LoadingIndicator();
            }
            if (state is NotificationsError) {
              return ErrorView(
                message: state.message,
                onRetry: () =>
                    context.read<NotificationsBloc>().add(const NotificationsLoadRequested()),
              );
            }
            if (state is NotificationsLoaded) {
              if (state.notifications.isEmpty) {
                return const EmptyState(
                  icon: Icons.notifications_none,
                  title: 'No notifications',
                  subtitle: 'You\'re all caught up!',
                );
              }
              return ListView.separated(
                itemCount: state.notifications.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final notification = state.notifications[index];
                  return _buildNotificationTile(context, notification);
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, AppNotification notification) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: notification.isRead
            ? Colors.grey[200]
            : Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          _iconForType(notification.type),
          color: notification.isRead
              ? Colors.grey
              : Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notification.body, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(
            timeago.format(notification.createdAt),
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
      isThreeLine: true,
      onTap: () {
        context.read<NotificationsBloc>().add(
              NotificationMarkReadRequested(notificationId: notification.id),
            );
        if (notification.tradeId != null) {
          context.go('/trades/${notification.tradeId}');
        }
      },
    );
  }
}
