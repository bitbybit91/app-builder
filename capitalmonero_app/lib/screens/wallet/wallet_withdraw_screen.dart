import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/constants.dart';
import '../../providers/wallet_provider.dart';

class WalletWithdrawScreen extends StatefulWidget {
  const WalletWithdrawScreen({super.key, this.args});
  final Map<String, dynamic>? args;

  @override
  State<WalletWithdrawScreen> createState() => _WalletWithdrawScreenState();
}

class _WalletWithdrawScreenState extends State<WalletWithdrawScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initial = widget.args?['crypto'] as String?;
    _selectedIndex = initial == CryptoCurrencies.xmr ? 1 : 0;
    _tabController = TabController(
        length: 2, vsync: this, initialIndex: _selectedIndex);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedIndex = _tabController.index;
          _amountController.clear();
          _addressController.clear();
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().fetchWallets();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  double _availableBalance(WalletProvider provider) {
    final wallet = _selectedIndex == 0
        ? provider.btcWallet
        : provider.xmrWallet;
    return wallet?.availableBalance ?? 0;
  }

  String get _selectedCrypto =>
      _selectedIndex == 0 ? CryptoCurrencies.btc : CryptoCurrencies.xmr;

  Future<void> _confirm(WalletProvider provider) async {
    final address = _addressController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a recipient address')),
      );
      return;
    }
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }
    final available = _availableBalance(provider);
    if (amount > available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient balance')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Withdrawal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: $amount $_selectedCrypto'),
            const SizedBox(height: 4),
            Text('To: ${address.substring(0, 10)}...'),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final success = await provider.withdraw(
          _selectedCrypto, address, amount);
      if (!mounted) return;
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Withdrawal submitted!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(provider.error ?? 'Withdrawal failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Withdraw'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'BTC'), Tab(text: 'XMR')],
        ),
      ),
      body: Consumer<WalletProvider>(
        builder: (context, provider, _) {
          final available = _availableBalance(provider);
          return TabBarView(
            controller: _tabController,
            children: List.generate(2, (index) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Available Balance',
                              style: TextStyle(
                                  color: AppColors.textMuted)),
                          Text(
                            '${available.toStringAsFixed(8)} $_selectedCrypto',
                            style: const TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: '$_selectedCrypto Address',
                        prefixIcon: const Icon(Icons.send_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Amount ($_selectedCrypto)',
                              prefixIcon: const Icon(
                                  Icons.currency_bitcoin),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            _amountController.text =
                                available.toStringAsFixed(8);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.bgInput,
                            foregroundColor: AppColors.textPrimary,
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 16),
                          ),
                          child: const Text('MAX'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Estimated network fee: ~0.00001 $_selectedCrypto',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 24),
                    if (provider.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          provider.error!,
                          style: const TextStyle(
                              color: AppColors.danger, fontSize: 13),
                        ),
                      ),
                    ElevatedButton(
                      onPressed: provider.loading
                          ? null
                          : () => _confirm(provider),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger),
                      child: provider.loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white),
                            )
                          : const Text('Withdraw'),
                    ),
                  ],
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
