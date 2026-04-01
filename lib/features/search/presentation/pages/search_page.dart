import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _selectedCoin = 'XMR';
  String _selectedType = 'buy';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Offers')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Row(children: [
                Expanded(child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'XMR', label: Text('XMR')),
                    ButtonSegment(value: 'BTC', label: Text('BTC')),
                  ],
                  selected: {_selectedCoin},
                  onSelectionChanged: (v) => setState(() => _selectedCoin = v.first),
                )),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'buy', label: Text('Buy')),
                    ButtonSegment(value: 'sell', label: Text('Sell')),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (v) => setState(() => _selectedType = v.first),
                )),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Payment Method', isDense: true),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Methods')),
                    DropdownMenuItem(value: 'bank', child: Text('Bank Transfer')),
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  ],
                  onChanged: (_) {},
                  value: 'all',
                )),
                const SizedBox(width: 16),
                Expanded(child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Currency', isDense: true),
                  items: const [
                    DropdownMenuItem(value: 'USD', child: Text('USD')),
                    DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                    DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                  ],
                  onChanged: (_) {},
                  value: 'USD',
                )),
              ]),
            ]),
          ),
          const Divider(),
          Expanded(
            child: Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.search, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('No offers found', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                const SizedBox(height: 8),
                const Text('Try adjusting your search filters'),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
