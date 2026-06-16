import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../domain/entities/wallet_balance.dart';
import '../bloc/wallet_bloc.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<WalletBloc>()..add(const WalletLoadRequested()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Wallet'),
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {},
              tooltip: 'Transaction History',
            ),
          ],
        ),
        body: BlocBuilder<WalletBloc, WalletState>(
          builder: (context, state) {
            if (state is WalletLoading) {
              return const LoadingIndicator();
            }
            if (state is WalletError) {
              return ErrorView(
                message: state.message,
                onRetry: () {
                  context.read<WalletBloc>().add(const WalletRefreshRequested());
                },
              );
            }
            if (state is WalletLoaded) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<WalletBloc>().add(const WalletRefreshRequested());
                },
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (state.balances.isEmpty)
                      _buildEmptyWallet(context)
                    else
                      ...state.balances.map((balance) =>
                          _buildBalanceCard(context, balance)),
                    const SizedBox(height: 16),
                    _buildQuickActions(context),
                  ],
                ),
              );
            }
            // Default: show placeholder wallet cards
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildPlaceholderCard(context, 'XMR', 'Monero', AppTheme.xmrColor),
                const SizedBox(height: 12),
                _buildPlaceholderCard(context, 'BTC', 'Bitcoin', AppTheme.btcColor),
                const SizedBox(height: 16),
                _buildQuickActions(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyWallet(BuildContext context) {
    return Column(
      children: [
        _buildPlaceholderCard(context, 'XMR', 'Monero', AppTheme.xmrColor),
        const SizedBox(height: 12),
        _buildPlaceholderCard(context, 'BTC', 'Bitcoin', AppTheme.btcColor),
      ],
    );
  }

  Widget _buildPlaceholderCard(
    BuildContext context,
    String symbol,
    String name,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.1),
                  child: Text(
                    symbol[0],
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(symbol, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '0.000000 $symbol',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Available: 0.000000 | Pending: 0.000000',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showDepositDialog(context, symbol),
                    icon: const Icon(Icons.arrow_downward, size: 16),
                    label: const Text('Deposit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showWithdrawDialog(context, symbol),
                    icon: const Icon(Icons.arrow_upward, size: 16),
                    label: const Text('Withdraw'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, WalletBalance balance) {
    final currency = balance.currency;
    final color = currency == 'XMR' ? AppTheme.xmrColor : AppTheme.btcColor;
    final name = currency == 'XMR' ? 'Monero' : 'Bitcoin';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.1),
                  child: Text(currency[0],
                      style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(currency, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${balance.total} $currency',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Available: ${balance.available} | Pending: ${balance.pending}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showDepositDialog(context, currency),
                    icon: const Icon(Icons.arrow_downward, size: 16),
                    label: const Text('Deposit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showWithdrawDialog(context, currency),
                    icon: const Icon(Icons.arrow_upward, size: 16),
                    label: const Text('Withdraw'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quick Actions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Scan QR Code'),
              subtitle: const Text('Scan a cryptocurrency address'),
              onTap: () {},
              dense: true,
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Transaction History'),
              subtitle: const Text('View all transactions'),
              onTap: () {},
              dense: true,
            ),
          ],
        ),
      ),
    );
  }

  void _showDepositDialog(BuildContext context, String currency) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Deposit $currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Your deposit address:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: SelectableText(
                      'Loading address...',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Send only the specified cryptocurrency to this address. '
              'Sending other assets may result in permanent loss.',
              style: TextStyle(fontSize: 12, color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context, String currency) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Withdraw $currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: '$currency Address',
                hintText: 'Enter destination address',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount ($currency)',
                hintText: '0.000000',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }
}
