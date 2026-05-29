import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/wallet_balance.dart';
import '../bloc/wallet_bloc.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: AppConstants.supportedCoins.length, vsync: this);
    final WalletBloc bloc = context.read<WalletBloc>();
    bloc.add(WalletLoadRequested(AppConstants.supportedCoins.first));
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) {
        bloc.add(WalletLoadRequested(AppConstants.supportedCoins[_tabs.index]));
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.wallet),
        bottom: TabBar(
          controller: _tabs,
          tabs: <Widget>[
            for (final String c in AppConstants.supportedCoins) Tab(text: c),
          ],
        ),
      ),
      body: BlocBuilder<WalletBloc, WalletState>(
        builder: (BuildContext context, WalletState state) {
          if (state is WalletLoading || state is WalletInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is WalletError) {
            return Center(child: Text(state.failure.message));
          }
          final WalletLoaded loaded = state as WalletLoaded;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(l.balance, style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.crypto(loaded.balance.available, loaded.coin),
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      if (loaded.balance.pending > 0)
                        Text(
                          '+ ${Formatters.crypto(loaded.balance.pending, loaded.coin)} pending',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(l.depositAddress, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Center(
                child: QrImageView(
                  data: loaded.depositAddress,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                loaded.depositAddress,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TextButton.icon(
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy'),
                    onPressed: () => Clipboard.setData(
                        ClipboardData(text: loaded.depositAddress)),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: Text(l.generateNewAddress),
                    onPressed: () => context
                        .read<WalletBloc>()
                        .add(WalletNewAddressRequested(loaded.coin)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.outbond_outlined),
                label: Text(l.withdraw),
                onPressed: () => context.push('/wallet/withdraw/${loaded.coin}'),
              ),
              const SizedBox(height: 24),
              Text(l.transactionHistory, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (loaded.history.isEmpty)
                Text(l.noTransactions),
              for (final WalletTransaction tx in loaded.history)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    tx.direction == TxDirection.incoming
                        ? Icons.south_west
                        : Icons.north_east,
                    color: tx.direction == TxDirection.incoming
                        ? Colors.green
                        : Colors.red,
                  ),
                  title: Text(Formatters.crypto(tx.amount, tx.coin)),
                  subtitle: Text(
                    '${Formatters.timeAgo(tx.timestamp)} • ${tx.confirmations} confs',
                  ),
                  trailing: tx.txHash == null
                      ? null
                      : Text(Formatters.shortHash(tx.txHash!)),
                ),
            ],
          );
        },
      ),
    );
  }
}
