import 'package:flutter/material.dart';

class TradeChatScreen extends StatelessWidget {
  final String tradeId;

  const TradeChatScreen({super.key, required this.tradeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trade Chat')),
      body: Center(child: Text('Chat for trade: $tradeId')),
    );
  }
}
