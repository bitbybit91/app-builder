import 'package:flutter/material.dart';

class OfferDetailScreen extends StatelessWidget {
  final String offerId;

  const OfferDetailScreen({super.key, required this.offerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offer Detail')),
      body: Center(child: Text('Offer: $offerId')),
    );
  }
}
