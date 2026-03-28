import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/constants.dart';
import '../../models/swap.dart';
import '../../providers/wallet_provider.dart';

class WalletSwapScreen extends StatefulWidget {
  const WalletSwapScreen({super.key});

  @override
  State<WalletSwapScreen> createState() => _WalletSwapScreenState();
}

class _WalletSwapScreenState extends State<WalletSwapScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _fromCrypto = CryptoCurrencies.btc;
  String _toCrypto = CryptoCurrencies.xmr;
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<WalletProvider>();
      p.fetchWallets();
      p.fetchSwapHistory();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _swapDirection() {
    setState(() {
      final tmp = _fromCrypto;
      _fromCrypto = _toCrypto;
      _toCrypto = tmp;
    });
  }

  Future<void> _executeSwap(WalletProvider provider) async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }
    final success =
        await provider.swap(_fromCrypto, _toCrypto, amount);
    if (!mounted) return;
    if (success) {
      _amountController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Swap executed successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(provider.error ?? 'Swap failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Swap'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Swap'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: Consumer<WalletProvider>(
        builder: (context, provider, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              // Swap tab
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Swap Cryptocurrency',
                        style:
                            Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 20),
                    // From
                    _CryptoSelector(
                      label: 'From',
                      value: _fromCrypto,
                      onChanged: (v) => setState(() {
                        _fromCrypto = v;
                        if (_fromCrypto == _toCrypto) {
                          _toCrypto = _fromCrypto ==
                                  CryptoCurrencies.btc
                              ? CryptoCurrencies.xmr
                              : CryptoCurrencies.btc;
                        }
                      }),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: IconButton(
                        onPressed: _swapDirection,
                        icon: const Icon(Icons.swap_vert,
                            color: AppColors.accent, size: 32),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // To
                    _CryptoSelector(
                      label: 'To',
                      value: _toCrypto,
                      onChanged: (v) => setState(() {
                        _toCrypto = v;
                        if (_toCrypto == _fromCrypto) {
                          _fromCrypto = _toCrypto ==
                                  CryptoCurrencies.btc
                              ? CryptoCurrencies.xmr
                              : CryptoCurrencies.btc;
                        }
                      }),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Amount ($_fromCrypto)',
                        prefixIcon: const Icon(Icons.currency_exchange),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Estimated receive',
                                  style: TextStyle(
                                      color: AppColors.textMuted)),
                              Text(
                                '≈ calculating...',
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Fee',
                                  style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12)),
                              Text('0.1%',
                                  style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
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
                          : () => _executeSwap(provider),
                      child: provider.loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white),
                            )
                          : Text(
                              'Swap $_fromCrypto → $_toCrypto'),
                    ),
                  ],
                ),
              ),

              // History tab
              provider.swaps.isEmpty
                  ? const Center(
                      child: Text('No swap history',
                          style:
                              TextStyle(color: AppColors.textMuted)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: provider.swaps.length,
                      itemBuilder: (context, index) =>
                          _SwapCard(swap: provider.swaps[index]),
                    ),
            ],
          );
        },
      ),
    );
  }
}

class _CryptoSelector extends StatelessWidget {
  const _CryptoSelector({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 12)),
          const Spacer(),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: AppColors.bgCard,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600),
              items: CryptoCurrencies.all
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c),
                      ))
                  .toList(),
              onChanged: (v) => onChanged(v!),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwapCard extends StatelessWidget {
  const _SwapCard({required this.swap});
  final Swap swap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.swap_horiz, color: AppColors.info),
        title: Text(
          '${swap.fromCrypto} → ${swap.toCrypto}',
          style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${swap.fromAmount.toStringAsFixed(8)} → ${swap.toAmount.toStringAsFixed(8)}',
          style:
              const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: swap.status == 'completed'
                ? AppColors.success.withOpacity(0.15)
                : AppColors.warning.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            swap.status.toUpperCase(),
            style: TextStyle(
              color: swap.status == 'completed'
                  ? AppColors.success
                  : AppColors.warning,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
