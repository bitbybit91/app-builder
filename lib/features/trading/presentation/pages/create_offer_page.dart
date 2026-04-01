import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/offer.dart';

class CreateOfferPage extends StatefulWidget {
  const CreateOfferPage({super.key});

  @override
  State<CreateOfferPage> createState() => _CreateOfferPageState();
}

class _CreateOfferPageState extends State<CreateOfferPage> {
  final _formKey = GlobalKey<FormState>();
  OfferType _offerType = OfferType.sell;
  TradeType _tradeType = TradeType.online;
  String _coinType = 'XMR';
  String _fiatCurrency = 'USD';
  PaymentMethod _paymentMethod = PaymentMethod.bankTransfer;
  final _minAmountController = TextEditingController();
  final _maxAmountController = TextEditingController();
  final _marginController = TextEditingController(text: '5');
  final _termsController = TextEditingController();

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _marginController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Offer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<OfferType>(
                segments: const [
                  ButtonSegment(value: OfferType.buy, label: Text('Buy'), icon: Icon(Icons.arrow_downward)),
                  ButtonSegment(value: OfferType.sell, label: Text('Sell'), icon: Icon(Icons.arrow_upward)),
                ],
                selected: {_offerType},
                onSelectionChanged: (v) => setState(() => _offerType = v.first),
              ),
              const SizedBox(height: 16),
              SegmentedButton<TradeType>(
                segments: const [
                  ButtonSegment(value: TradeType.online, label: Text('Online'), icon: Icon(Icons.public)),
                  ButtonSegment(value: TradeType.localCash, label: Text('Local Cash'), icon: Icon(Icons.location_on)),
                ],
                selected: {_tradeType},
                onSelectionChanged: (v) => setState(() => _tradeType = v.first),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _coinType,
                decoration: const InputDecoration(labelText: 'Cryptocurrency'),
                items: const [
                  DropdownMenuItem(value: 'XMR', child: Text('Monero (XMR)')),
                  DropdownMenuItem(value: 'BTC', child: Text('Bitcoin (BTC)')),
                ],
                onChanged: (v) => setState(() => _coinType = v ?? 'XMR'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _fiatCurrency,
                decoration: const InputDecoration(labelText: 'Fiat Currency'),
                items: const [
                  DropdownMenuItem(value: 'USD', child: Text('USD')),
                  DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                  DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                ],
                onChanged: (v) => setState(() => _fiatCurrency = v ?? 'USD'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PaymentMethod>(
                value: _paymentMethod,
                decoration: const InputDecoration(labelText: 'Payment Method'),
                items: PaymentMethod.values.map((m) => DropdownMenuItem(value: m, child: Text(m.name))).toList(),
                onChanged: (v) => setState(() => _paymentMethod = v ?? PaymentMethod.bankTransfer),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: TextFormField(
                  controller: _minAmountController,
                  decoration: const InputDecoration(labelText: 'Min Amount'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                )),
                const SizedBox(width: 16),
                Expanded(child: TextFormField(
                  controller: _maxAmountController,
                  decoration: const InputDecoration(labelText: 'Max Amount'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                )),
              ]),
              const SizedBox(height: 16),
              TextFormField(
                controller: _marginController,
                decoration: const InputDecoration(labelText: 'Margin %', suffixText: '%'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _termsController,
                decoration: const InputDecoration(labelText: 'Trade Terms'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _createOffer,
                child: const Text('Create Offer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createOffer() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offer created successfully!')),
      );
      context.go('/home');
    }
  }
}
