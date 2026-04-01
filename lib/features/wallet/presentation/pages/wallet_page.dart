import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Monero (XMR)'), Tab(text: 'Bitcoin (BTC)')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWalletView('XMR', '0.00000000', '4...address'),
          _buildWalletView('BTC', '0.00000000', 'bc1...address'),
        ],
      ),
    );
  }

  Widget _buildWalletView(String coin, String balance, String address) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                Text('$coin Balance', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(balance, style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('≈ \$0.00 USD', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: FilledButton.icon(onPressed: () => _showDepositDialog(coin, address), icon: const Icon(Icons.arrow_downward), label: const Text('Deposit'))),
            const SizedBox(width: 16),
            Expanded(child: OutlinedButton.icon(onPressed: () => _showWithdrawDialog(coin), icon: const Icon(Icons.arrow_upward), label: const Text('Withdraw'))),
          ]),
          const SizedBox(height: 24),
          Text('Transaction History', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Card(child: Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No transactions yet')))),
        ],
      ),
    );
  }

  void _showDepositDialog(String coin, String address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Deposit $coin'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Send funds to this address:'),
          const SizedBox(height: 16),
          SelectableText(address, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: address));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address copied!')));
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy Address'),
          ),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _showWithdrawDialog(String coin) {
    final addressController = TextEditingController();
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Withdraw $coin'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Recipient Address')),
          const SizedBox(height: 16),
          TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.number),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Withdraw')),
        ],
      ),
    );
  }
}
