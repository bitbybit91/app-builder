import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/trade.dart';
import '../bloc/trade_bloc.dart';

class TradePage extends StatelessWidget {
  const TradePage({super.key, required this.tradeId});
  final String tradeId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TradeBloc>(
      create: (_) => sl<TradeBloc>()..add(TradeLoadRequested(tradeId)),
      child: _TradeView(tradeId: tradeId),
    );
  }
}

class _TradeView extends StatelessWidget {
  const _TradeView({required this.tradeId});
  final String tradeId;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AuthState authState = context.watch<AuthBloc>().state;
    final String me = authState is AuthAuthenticated
        ? authState.session.user.username
        : 'guest';

    return BlocBuilder<TradeBloc, TradeState>(
      builder: (BuildContext context, TradeState state) {
        if (state is TradeLoading || state is TradeInitial) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (state is TradeError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(state.failure.message)),
          );
        }
        final Trade t = (state as TradeLoaded).trade;
        final TradeRole role = t.roleFor(me);
        return Scaffold(
          appBar: AppBar(
            title: Text('${l.trade} #${t.id.substring(0, 6)}'),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: () => context.push('/trades/${t.id}/chat'),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _StatusChip(status: t.status),
              const SizedBox(height: 12),
              _Row(label: 'Coin', value: t.coin),
              _Row(
                  label: l.amount,
                  value: '${Formatters.crypto(t.cryptoAmount, t.coin)} '
                      '(${Formatters.fiat(t.fiatAmount, t.fiatCurrency)})'),
              _Row(label: l.paymentMethod, value: t.paymentMethod),
              _Row(
                  label: role == TradeRole.buyer ? l.selling : l.buying,
                  value: role == TradeRole.buyer ? t.sellerUsername : t.buyerUsername),
              if (t.escrowAddress != null)
                _Row(label: 'Escrow', value: t.escrowAddress!),
              const Divider(),
              _Actions(trade: t, role: role),
              TextButton(
                onPressed: () => context.push('/trades/${t.id}/dispute'),
                child: Text(l.openDispute),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: 140, child: Text(label, style: Theme.of(context).textTheme.labelLarge)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final TradeStatus status;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case TradeStatus.released:
      case TradeStatus.resolvedForBuyer:
      case TradeStatus.resolvedForSeller:
        color = Colors.green;
        break;
      case TradeStatus.cancelled:
        color = Colors.grey;
        break;
      case TradeStatus.disputed:
        color = Colors.red;
        break;
      default:
        color = Theme.of(context).colorScheme.primary;
    }
    return Chip(
      label: Text(status.name),
      backgroundColor: color.withValues(alpha: 0.18),
      side: BorderSide(color: color),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.trade, required this.role});
  final Trade trade;
  final TradeRole role;

  void _dispatch(BuildContext context, TradeAction action) {
    context.read<TradeBloc>().add(TradeActionRequested(trade.id, action));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final List<Widget> actions = <Widget>[];
    if (role == TradeRole.seller && trade.status == TradeStatus.created) {
      actions.add(FilledButton(
        onPressed: () => _dispatch(context, TradeAction.fund),
        child: Text(l.fundEscrow),
      ));
    }
    if (role == TradeRole.buyer && trade.status == TradeStatus.funded) {
      actions.add(FilledButton(
        onPressed: () => _dispatch(context, TradeAction.paymentSent),
        child: Text(l.markPaymentSent),
      ));
    }
    if (role == TradeRole.seller && trade.status == TradeStatus.paymentSent) {
      actions.add(FilledButton(
        onPressed: () => _dispatch(context, TradeAction.paymentReceived),
        child: Text(l.markPaymentReceived),
      ));
    }
    if (role == TradeRole.seller && trade.status == TradeStatus.paymentReceived) {
      actions.add(FilledButton(
        onPressed: () => _dispatch(context, TradeAction.release),
        child: Text(l.releaseEscrow),
      ));
    }
    if (trade.isActive && trade.status != TradeStatus.disputed) {
      actions.add(OutlinedButton(
        onPressed: () => _dispatch(context, TradeAction.cancel),
        child: Text(l.cancel),
      ));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final Widget w in actions) ...<Widget>[
          w,
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
