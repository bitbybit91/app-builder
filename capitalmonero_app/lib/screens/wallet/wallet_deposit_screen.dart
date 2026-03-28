import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../config/app_theme.dart';
import '../../config/constants.dart';
import '../../providers/wallet_provider.dart';

class WalletDepositScreen extends StatefulWidget {
  const WalletDepositScreen({super.key, this.args});
  final Map<String, dynamic>? args;

  @override
  State<WalletDepositScreen> createState() => _WalletDepositScreenState();
}

class _WalletDepositScreenState extends State<WalletDepositScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    final initial = widget.args?['crypto'] as String?;
    _selectedIndex = initial == CryptoCurrencies.xmr ? 1 : 0;
    _tabController = TabController(length: 2, vsync: this, initialIndex: _selectedIndex);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedIndex = _tabController.index);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().fetchWallets();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _copyAddress(String address) {
    Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Address copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deposit'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'BTC'),
            Tab(text: 'XMR'),
          ],
        ),
      ),
      body: Consumer<WalletProvider>(
        builder: (context, provider, _) {
          final wallet = _selectedIndex == 0
              ? provider.btcWallet
              : provider.xmrWallet;
          final crypto = _selectedIndex == 0
              ? CryptoCurrencies.btc
              : CryptoCurrencies.xmr;
          final address = wallet?.address;

          return TabBarView(
            controller: _tabController,
            children: [
              _DepositTab(
                crypto: CryptoCurrencies.btc,
                address: provider.btcWallet?.address,
                onCopy: _copyAddress,
              ),
              _DepositTab(
                crypto: CryptoCurrencies.xmr,
                address: provider.xmrWallet?.address,
                onCopy: _copyAddress,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DepositTab extends StatelessWidget {
  const _DepositTab({
    required this.crypto,
    required this.address,
    required this.onCopy,
  });
  final String crypto;
  final String? address;
  final void Function(String) onCopy;

  @override
  Widget build(BuildContext context) {
    final isBtc = crypto == CryptoCurrencies.btc;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Your $crypto Deposit Address',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Send only $crypto to this address.',
            style: const TextStyle(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          if (address != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: address!,
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      address!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: AppColors.accent),
                    onPressed: () => onCopy(address!),
                  ),
                ],
              ),
            ),
          ] else
            const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.warning.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: AppColors.warning, size: 18),
                    SizedBox(width: 6),
                    Text('Important',
                        style: TextStyle(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Minimum deposit: ${isBtc ? '0.0001 BTC' : '0.01 XMR'}\n'
                  '• Deposits require ${isBtc ? '3' : '10'} confirmations\n'
                  '• Only send $crypto to this address',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
