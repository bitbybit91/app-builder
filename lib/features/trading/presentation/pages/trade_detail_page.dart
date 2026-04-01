import 'package:flutter/material.dart';
import '../../domain/entities/trade.dart';

class TradeDetailPage extends StatelessWidget {
  final String tradeId;
  const TradeDetailPage({super.key, required this.tradeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Trade #$tradeId')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Trade Details', style: Theme.of(context).textTheme.titleLarge),
                    const Divider(),
                    _buildDetailRow('Trade ID', tradeId),
                    _buildDetailRow('Status', TradeStatus.created.name),
                    _buildDetailRow('Coin', 'XMR'),
                    _buildDetailRow('Amount', '0.5 XMR'),
                    _buildDetailRow('Price', '\$150.00'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Trade Chat', style: Theme.of(context).textTheme.titleLarge),
                    const Divider(),
                    const SizedBox(height: 100, child: Center(child: Text('No messages yet'))),
                    TextField(decoration: InputDecoration(
                      hintText: 'Type a message...',
                      suffixIcon: IconButton(icon: const Icon(Icons.send), onPressed: () {}),
                    )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('Cancel Trade'))),
              const SizedBox(width: 16),
              Expanded(child: FilledButton(onPressed: () {}, child: const Text('Mark Payment Sent'))),
            ]),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.report),
              label: const Text('Open Dispute'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: const TextStyle(fontWeight: FontWeight.w500)), Text(value)],
      ),
    );
  }
}
