import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/offer_provider.dart';

class OfferCreateScreen extends StatefulWidget {
  const OfferCreateScreen({super.key, this.args});
  final Map<String, dynamic>? args;

  @override
  State<OfferCreateScreen> createState() => _OfferCreateScreenState();
}

class _OfferCreateScreenState extends State<OfferCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'buy';
  String _crypto = CryptoCurrencies.btc;
  String _fiatCurrency = FiatCurrencies.usd;
  String _paymentMethod = PaymentMethods.all.first;
  String _priceType = 'margin';
  final _fixedPriceController = TextEditingController();
  final _marginController = TextEditingController(text: '1.0');
  final _minAmountController = TextEditingController();
  final _maxAmountController = TextEditingController();
  final _paymentWindowController = TextEditingController(text: '60');
  final _termsController = TextEditingController();

  @override
  void dispose() {
    _fixedPriceController.dispose();
    _marginController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _paymentWindowController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      Navigator.pushNamed(context, AppRoutes.login);
      return;
    }

    final data = <String, dynamic>{
      'type': _type,
      'crypto': _crypto,
      'fiat_currency': _fiatCurrency,
      'price_type': _priceType,
      'payment_method': _paymentMethod,
      'min_amount': double.tryParse(_minAmountController.text) ?? 0,
      'max_amount': double.tryParse(_maxAmountController.text) ?? 0,
      'payment_window': int.tryParse(_paymentWindowController.text) ?? 60,
      'terms': _termsController.text.trim(),
    };
    if (_priceType == 'fixed') {
      data['fixed_price'] =
          double.tryParse(_fixedPriceController.text) ?? 0;
    } else {
      data['price_margin'] =
          double.tryParse(_marginController.text) ?? 1;
    }

    final success =
        await context.read<OfferProvider>().createOffer(data);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Offer created successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      final err = context.read<OfferProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Failed to create offer')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OfferProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Create Offer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Buy / Sell toggle
              _SectionLabel('Offer Type'),
              Row(
                children: [
                  Expanded(
                    child: _ToggleButton(
                      label: 'BUY',
                      selected: _type == 'buy',
                      color: AppColors.success,
                      onTap: () => setState(() => _type = 'buy'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ToggleButton(
                      label: 'SELL',
                      selected: _type == 'sell',
                      color: AppColors.danger,
                      onTap: () => setState(() => _type = 'sell'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Crypto selector
              _SectionLabel('Cryptocurrency'),
              DropdownButtonFormField<String>(
                value: _crypto,
                dropdownColor: AppColors.bgCard,
                decoration: const InputDecoration(hintText: 'Select crypto'),
                items: CryptoCurrencies.all
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _crypto = v!),
              ),
              const SizedBox(height: 16),

              // Fiat currency
              _SectionLabel('Fiat Currency'),
              DropdownButtonFormField<String>(
                value: _fiatCurrency,
                dropdownColor: AppColors.bgCard,
                decoration: const InputDecoration(hintText: 'Select currency'),
                items: FiatCurrencies.all
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _fiatCurrency = v!),
              ),
              const SizedBox(height: 16),

              // Payment method
              _SectionLabel('Payment Method'),
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                dropdownColor: AppColors.bgCard,
                decoration:
                    const InputDecoration(hintText: 'Select payment method'),
                items: PaymentMethods.all
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(m),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _paymentMethod = v!),
              ),
              const SizedBox(height: 16),

              // Price type
              _SectionLabel('Price Type'),
              Row(
                children: [
                  Expanded(
                    child: _ToggleButton(
                      label: 'Margin %',
                      selected: _priceType == 'margin',
                      color: AppColors.accent,
                      onTap: () => setState(() => _priceType = 'margin'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ToggleButton(
                      label: 'Fixed',
                      selected: _priceType == 'fixed',
                      color: AppColors.accent,
                      onTap: () => setState(() => _priceType = 'fixed'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_priceType == 'fixed')
                TextFormField(
                  controller: _fixedPriceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Fixed Price ($_fiatCurrency)',
                    prefixIcon: const Icon(Icons.attach_money),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (double.tryParse(v) == null) return 'Invalid number';
                    return null;
                  },
                )
              else
                TextFormField(
                  controller: _marginController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Margin above market (%)',
                    prefixIcon: Icon(Icons.percent),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (double.tryParse(v) == null) return 'Invalid number';
                    return null;
                  },
                ),
              const SizedBox(height: 16),

              // Min / Max amounts
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minAmountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Min ($_fiatCurrency)',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _maxAmountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Max ($_fiatCurrency)',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid';
                        final min =
                            double.tryParse(_minAmountController.text) ?? 0;
                        final max = double.tryParse(v) ?? 0;
                        if (max < min) return 'Max < Min';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Payment window
              TextFormField(
                controller: _paymentWindowController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Payment Window (minutes)',
                  prefixIcon: Icon(Icons.timer_outlined),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final n = int.tryParse(v);
                  if (n == null || n < 15) return 'Min 15 minutes';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Terms
              TextFormField(
                controller: _termsController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Trade Terms (optional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: provider.loading ? null : _submit,
                child: provider.loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Create Offer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.2) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
