import 'package:flutter/material.dart';

class TradeScreen extends StatelessWidget {
  final String tradeId;

  const TradeScreen({super.key, required this.tradeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trade')),
      body: Center(child: Text('Trade: $tradeId')),
    );
  }
}
