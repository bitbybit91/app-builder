import 'package:flutter/material.dart';

class PinScreen extends StatelessWidget {
  /// `mode` is either `'setup'` or `'entry'` (passed as a GoRouter query param).
  final String mode;

  const PinScreen({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(mode == 'setup' ? 'Create PIN' : 'Enter PIN'),
      ),
      body: const Center(child: Text('PIN Screen')),
    );
  }
}
