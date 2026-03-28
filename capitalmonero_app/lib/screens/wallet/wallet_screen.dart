import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../config/app_theme.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../models/transaction.dart';
import '../../providers/wallet_provider.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<WalletProvider>();
      provider.fetchWallets();
      provider.fetchTransactions(refresh: true);
    });
  }

  void _copyAddress(BuildContext context, String address) {
    Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Address copied to clipboard')),
    );
  }

  void _showQr(BuildContext context, String address, String crypto) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$crypto Deposit Address'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: address,
                size: 180,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              address,
              style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: Consumer<WalletProvider>(
        builder: (context, provider, _) {
          if (provider.loading && provider.wallets.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: () async {
              await provider.fetchWallets();
              await provider.fetchTransactions(refresh: true);
            },
            color: AppColors.accent,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // BTC Wallet Card
                _buildWalletCard(
                  context,
                  provider,
                  CryptoCurrencies.btc,
                  provider.btcWallet?.balance ?? 0,
                  provider.btcWallet?.availableBalance ?? 0,
                  provider.btcWallet?.lockedBalance ?? 0,
                  provider.btcWallet?.address,
                  const Color(0xFFF7931A),
                ),
                const SizedBox(height: 12),

                // XMR Wallet Card
                _buildWalletCard(
                  context,
                  provider,
                  CryptoCurrencies.xmr,
                  provider.xmrWallet?.balance ?? 0,
                  provider.xmrWallet?.availableBalance ?? 0,
                  provider.xmrWallet?.lockedBalance ?? 0,
                  provider.xmrWallet?.address,
                  AppColors.moneroOrange,
                ),
                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: _ActionBtn(
                        icon: Icons.arrow_downward,
                        label: 'Deposit',
                        color: AppColors.success,
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.walletDeposit),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionBtn(
                        icon: Icons.arrow_upward,
                        label: 'Withdraw',
                        color: AppColors.danger,
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.walletWithdraw),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionBtn(
                        icon: Icons.swap_horiz,
                        label: 'Swap',
                        color: AppColors.info,
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.walletSwap),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Transaction history
                Text(
                  'Transaction History',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                if (provider.transactions.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No transactions yet',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  )
                else
                  ...provider.transactions
                      .map((tx) => _TransactionItem(transaction: tx)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWalletCard(
    BuildContext context,
    WalletProvider provider,
    String crypto,
    double balance,
    double available,
    double locked,
    String? address,
    Color cryptoColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cryptoColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cryptoColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  crypto,
                  style: TextStyle(
                      color: cryptoColor, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                balance.toStringAsFixed(8),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _BalanceItem(
                  label: 'Available',
                  value: available.toStringAsFixed(8),
                  color: AppColors.success),
              const SizedBox(width: 16),
              _BalanceItem(
                  label: 'Locked',
                  value: locked.toStringAsFixed(8),
                  color: AppColors.warning),
            ],
          ),
          if (address != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${address.substring(0, 10)}...${address.substring(address.length - 8)}',
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        color: AppColors.textMuted,
                        fontSize: 12),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy,
                      color: AppColors.textMuted, size: 18),
                  onPressed: () => _copyAddress(context, address),
                  tooltip: 'Copy address',
                ),
                IconButton(
                  icon: const Icon(Icons.qr_code,
                      color: AppColors.textMuted, size: 18),
                  onPressed: () =>
                      _showQr(context, address, crypto),
                  tooltip: 'Show QR',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BalanceItem extends StatelessWidget {
  const _BalanceItem(
      {required this.label,
      required this.value,
      required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w500, fontSize: 13)),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  const _TransactionItem({required this.transaction});
  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final isDeposit = transaction.type == 'deposit';
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isDeposit ? AppColors.success : AppColors.danger)
                .withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
            color: isDeposit ? AppColors.success : AppColors.danger,
            size: 18,
          ),
        ),
        title: Text(
          '${transaction.type.toUpperCase()} ${transaction.crypto}',
          style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          transaction.status,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isDeposit ? '+' : '-'}${transaction.amount.toStringAsFixed(8)}',
              style: TextStyle(
                color:
                    isDeposit ? AppColors.success : AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              transaction.crypto,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
