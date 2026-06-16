import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../bloc/offers_bloc.dart';

class CreateOfferPage extends StatefulWidget {
  const CreateOfferPage({super.key});

  @override
  State<CreateOfferPage> createState() => _CreateOfferPageState();
}

class _CreateOfferPageState extends State<CreateOfferPage> {
  final _formKey = GlobalKey<FormState>();
  String _tradeType = 'SELL';
  String _offerType = 'ONLINE';
  String _cryptoCurrency = 'XMR';
  String _fiatCurrency = 'USD';
  String _paymentMethod = 'Bank Transfer';
  final _minAmountController = TextEditingController();
  final _maxAmountController = TextEditingController();
  final _marginController = TextEditingController(text: '5');
  final _termsController = TextEditingController();
  bool _useFixedPrice = false;
  final _fixedPriceController = TextEditingController();

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _marginController.dispose();
    _termsController.dispose();
    _fixedPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OffersBloc>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Offer'),
        ),
        body: BlocConsumer<OffersBloc, OffersState>(
          listener: (context, state) {
            if (state is OfferCreated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Offer created successfully')),
              );
              context.pop();
            } else if (state is OffersError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Trade Type
                    const Text('I want to', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'BUY', label: Text('Buy')),
                        ButtonSegment(value: 'SELL', label: Text('Sell')),
                      ],
                      selected: {_tradeType},
                      onSelectionChanged: (v) => setState(() => _tradeType = v.first),
                    ),
                    const SizedBox(height: 16),

                    // Crypto Currency
                    const Text('Cryptocurrency', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'XMR', label: Text('Monero')),
                        ButtonSegment(value: 'BTC', label: Text('Bitcoin')),
                      ],
                      selected: {_cryptoCurrency},
                      onSelectionChanged: (v) => setState(() => _cryptoCurrency = v.first),
                    ),
                    const SizedBox(height: 16),

                    // Offer Type
                    const Text('Trade Type', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'ONLINE', label: Text('Online')),
                        ButtonSegment(value: 'LOCAL', label: Text('Local Cash')),
                      ],
                      selected: {_offerType},
                      onSelectionChanged: (v) => setState(() => _offerType = v.first),
                    ),
                    const SizedBox(height: 16),

                    // Fiat Currency
                    DropdownButtonFormField<String>(
                      value: _fiatCurrency,
                      decoration: const InputDecoration(labelText: 'Fiat Currency'),
                      items: ['USD', 'EUR', 'GBP', 'CAD', 'AUD', 'JPY', 'CHF']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() => _fiatCurrency = v!),
                    ),
                    const SizedBox(height: 16),

                    // Payment Method
                    DropdownButtonFormField<String>(
                      value: _paymentMethod,
                      decoration: const InputDecoration(labelText: 'Payment Method'),
                      items: [
                        'Bank Transfer',
                        'Cash (in person)',
                        'PayPal',
                        'Revolut',
                        'Wise',
                        'Cash by Mail',
                        'Cryptocurrency',
                        'Other',
                      ].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                      onChanged: (v) => setState(() => _paymentMethod = v!),
                    ),
                    const SizedBox(height: 16),

                    // Price
                    SwitchListTile(
                      value: _useFixedPrice,
                      onChanged: (v) => setState(() => _useFixedPrice = v),
                      title: const Text('Use Fixed Price'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (_useFixedPrice)
                      TextFormField(
                        controller: _fixedPriceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Fixed Price ($_fiatCurrency)',
                        ),
                        validator: (v) {
                          if (_useFixedPrice && (v == null || v.isEmpty)) {
                            return 'Enter a price';
                          }
                          return null;
                        },
                      )
                    else
                      TextFormField(
                        controller: _marginController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Market Price Margin (%)',
                          helperText: 'e.g., 5 for +5% above market',
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Amounts
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _minAmountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Min ($_fiatCurrency)',
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _maxAmountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Max ($_fiatCurrency)',
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Terms
                    TextFormField(
                      controller: _termsController,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: 'Terms of Trade',
                        helperText: 'Describe your trading terms',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (state is OfferCreating)
                      const LoadingIndicator()
                    else
                      ElevatedButton(
                        onPressed: _onSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Publish Offer',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      context.read<OffersBloc>().add(OfferCreateRequested(
            tradeType: _tradeType,
            offerType: _offerType,
            cryptoCurrency: _cryptoCurrency,
            fiatCurrency: _fiatCurrency,
            paymentMethod: _paymentMethod,
            fixedPrice: _useFixedPrice
                ? double.tryParse(_fixedPriceController.text)
                : null,
            marketPriceMargin: !_useFixedPrice
                ? double.tryParse(_marginController.text)
                : null,
            minAmount: double.parse(_minAmountController.text),
            maxAmount: double.parse(_maxAmountController.text),
            terms: _termsController.text.isNotEmpty ? _termsController.text : null,
          ));
    }
  }
}
