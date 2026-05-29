import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/trade.dart';
import '../bloc/trade_bloc.dart';

class TradeHistoryPage extends StatelessWidget {
  const TradeHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AuthState authState = context.watch<AuthBloc>().state;
    final String me = authState is AuthAuthenticated
        ? authState.session.user.username
        : 'guest';
    return BlocProvider<TradeBloc>(
      create: (_) =>
          sl<TradeBloc>()..add(TradeHistoryRequested(username: me)),
      child: Scaffold(
        appBar: AppBar(title: Text(l.tradeHistory)),
        body: BlocBuilder<TradeBloc, TradeState>(
          builder: (BuildContext context, TradeState state) {
            if (state is TradeLoading || state is TradeInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is TradeError) {
              return Center(child: Text(state.failure.message));
            }
            if (state is! TradeHistoryLoaded) {
              return const SizedBox.shrink();
            }
            final List<Trade> trades = state.trades;
            if (trades.isEmpty) {
              return const Center(child: Text('No trades yet'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(8),
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemCount: trades.length,
              itemBuilder: (BuildContext context, int i) {
                final Trade t = trades[i];
                return ListTile(
                  title: Text(
                      '${t.roleFor(me) == TradeRole.buyer ? "Buying" : "Selling"} '
                      '${Formatters.crypto(t.cryptoAmount, t.coin)}'),
                  subtitle: Text(
                      '${Formatters.fiat(t.fiatAmount, t.fiatCurrency)} • ${t.status.name}'),
                  trailing: Text(Formatters.timeAgo(t.createdAt)),
                  onTap: () => context.push('/trades/${t.id}'),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
