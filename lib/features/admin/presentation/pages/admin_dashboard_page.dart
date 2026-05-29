import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/repositories/admin_repository.dart';
import '../bloc/admin_bloc.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return BlocProvider<AdminBloc>(
      create: (_) => sl<AdminBloc>()..add(const AdminLoadRequested()),
      child: Scaffold(
        appBar: AppBar(title: Text(l.adminPanel)),
        body: BlocBuilder<AdminBloc, AdminState>(
          builder: (BuildContext context, AdminState state) {
            if (state is AdminLoading || state is AdminInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is AdminErrorState) {
              return Center(child: Text(state.failure.message));
            }
            final AdminLoaded loaded = state as AdminLoaded;
            return ListView(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(l.statistics,
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          _StatRow(label: l.users, value: loaded.stats.totalUsers.toString()),
                          _StatRow(label: l.offers, value: loaded.stats.activeOffers.toString()),
                          _StatRow(label: l.trades, value: loaded.stats.openTrades.toString()),
                          _StatRow(label: l.disputes, value: loaded.stats.openDisputes.toString()),
                          _StatRow(
                            label: 'Weekly volume (USD)',
                            value: Formatters.fiat(loaded.stats.weeklyVolumeUsd, 'USD'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Users', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                for (final User u in loaded.users)
                  ListTile(
                    leading: CircleAvatar(child: Text(u.username[0].toUpperCase())),
                    title: Text(u.username),
                    subtitle: Text('${u.tradeCount} trades • ${u.feedbackScore}%'),
                    trailing: PopupMenuButton<UserModerationAction>(
                      onSelected: (UserModerationAction action) {
                        context.read<AdminBloc>().add(AdminUserModerated(
                              username: u.username,
                              action: action,
                            ));
                      },
                      itemBuilder: (_) => <PopupMenuEntry<UserModerationAction>>[
                        PopupMenuItem<UserModerationAction>(
                            value: UserModerationAction.warn, child: Text(l.warn)),
                        PopupMenuItem<UserModerationAction>(
                            value: UserModerationAction.ban, child: Text(l.ban)),
                        PopupMenuItem<UserModerationAction>(
                            value: UserModerationAction.verify, child: Text(l.verify)),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: <Widget>[
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
