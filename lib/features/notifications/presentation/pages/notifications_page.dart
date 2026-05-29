import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/app_notification.dart';
import '../bloc/notifications_bloc.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.notifications),
        actions: <Widget>[
          TextButton(
            onPressed: () => context
                .read<NotificationsBloc>()
                .add(const NotificationsMarkAllRead()),
            child: Text(l.markAllRead),
          ),
        ],
      ),
      body: BlocBuilder<NotificationsBloc, NotificationsState>(
        builder: (BuildContext context, NotificationsState state) {
          if (state is NotificationsLoading || state is NotificationsInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is NotificationsErrorState) {
            return Center(child: Text(state.failure.message));
          }
          final List<AppNotification> items =
              (state as NotificationsLoaded).items;
          if (items.isEmpty) {
            return Center(child: Text(l.noNotifications));
          }
          return ListView.separated(
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemCount: items.length,
            itemBuilder: (BuildContext context, int i) {
              final AppNotification n = items[i];
              return ListTile(
                leading: Icon(_iconFor(n.kind)),
                title: Text(
                  n.title,
                  style: TextStyle(
                    fontWeight: n.read ? FontWeight.normal : FontWeight.w700,
                  ),
                ),
                subtitle: Text(n.body),
                trailing: Text(Formatters.timeAgo(n.createdAt)),
                onTap: () {
                  context
                      .read<NotificationsBloc>()
                      .add(NotificationsMarkRead(n.id));
                  if (n.deeplink != null) context.push(n.deeplink!);
                },
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconFor(NotificationKind kind) => switch (kind) {
        NotificationKind.tradeUpdate => Icons.swap_horiz,
        NotificationKind.newMessage => Icons.message_outlined,
        NotificationKind.disputeAlert => Icons.warning_amber,
        NotificationKind.system => Icons.info_outline,
      };
}
