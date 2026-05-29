import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import '../../core/security/session_manager.dart';
import '../../features/notifications/presentation/bloc/notifications_bloc.dart';
import '../../l10n/app_localizations.dart';

/// Bottom navigation host for the authenticated section of the app.
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.child});
  final Widget child;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const List<_Tab> _tabs = <_Tab>[
    _Tab('/offers', Icons.list_alt, Icons.list_alt_outlined),
    _Tab('/search', Icons.search, Icons.search_outlined),
    _Tab('/wallet', Icons.account_balance_wallet, Icons.account_balance_wallet_outlined),
    _Tab('/messages', Icons.message, Icons.message_outlined),
    _Tab('/profile', Icons.person, Icons.person_outline),
  ];

  int _currentIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final int idx = _currentIndex(context);
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => sl<SessionManager>().touch(),
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: idx,
          onDestinationSelected: (int i) => context.go(_tabs[i].path),
          destinations: <NavigationDestination>[
            NavigationDestination(
              selectedIcon: Icon(_tabs[0].selectedIcon),
              icon: Icon(_tabs[0].icon),
              label: l.offers,
            ),
            NavigationDestination(
              selectedIcon: Icon(_tabs[1].selectedIcon),
              icon: Icon(_tabs[1].icon),
              label: l.search,
            ),
            NavigationDestination(
              selectedIcon: Icon(_tabs[2].selectedIcon),
              icon: Icon(_tabs[2].icon),
              label: l.wallet,
            ),
            NavigationDestination(
              selectedIcon: _NotificationBadge(child: Icon(_tabs[3].selectedIcon)),
              icon: _NotificationBadge(child: Icon(_tabs[3].icon)),
              label: l.messages,
            ),
            NavigationDestination(
              selectedIcon: Icon(_tabs[4].selectedIcon),
              icon: Icon(_tabs[4].icon),
              label: l.profile,
            ),
          ],
        ),
        floatingActionButton: idx == 0
            ? FloatingActionButton.extended(
                onPressed: () => context.push('/notifications'),
                icon: const Icon(Icons.notifications_outlined),
                label: BlocBuilder<NotificationsBloc, NotificationsState>(
                  builder: (_, NotificationsState state) {
                    final int n = state is NotificationsLoaded ? state.unread : 0;
                    return Text(n > 0 ? '$n' : l.notifications);
                  },
                ),
              )
            : null,
      ),
    );
  }
}

class _Tab {
  const _Tab(this.path, this.selectedIcon, this.icon);
  final String path;
  final IconData selectedIcon;
  final IconData icon;
}

class _NotificationBadge extends StatelessWidget {
  const _NotificationBadge({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsBloc, NotificationsState>(
      builder: (BuildContext context, NotificationsState state) {
        final int n = state is NotificationsLoaded ? state.unread : 0;
        if (n == 0) return child;
        return Badge.count(count: n, child: child);
      },
    );
  }
}
