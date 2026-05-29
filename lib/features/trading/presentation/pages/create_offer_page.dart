import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/offer.dart';
import '../bloc/offers_bloc.dart';

class CreateOfferPage extends StatefulWidget {
  const CreateOfferPage({super.key});

  @override
  State<CreateOfferPage> createState() => _CreateOfferPageState();
}

class _CreateOfferPageState extends State<CreateOfferPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _priceCtrl =
      TextEditingController(text: 'market*1.02');
  final TextEditingController _minCtrl = TextEditingController(text: '50');
  final TextEditingController _maxCtrl = TextEditingController(text: '1000');
  final TextEditingController _termsCtrl = TextEditingController();
  final TextEditingController _countryCtrl = TextEditingController(text: 'US');
  final TextEditingController _cityCtrl = TextEditingController();

  String _coin = AppConstants.supportedCoins.first;
  String _fiat = AppConstants.supportedFiatCurrencies.first;
  String _paymentMethod = AppConstants.defaultPaymentMethods.first;
  OfferKind _kind = OfferKind.onlineSell;

  @override
  void dispose() {
    _priceCtrl.dispose();
    _minCtrl.dispose();
    _maxCtrl.dispose();
    _termsCtrl.dispose();
    _countryCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext context, String owner) {
    if (!_formKey.currentState!.validate()) return;
    final Offer draft = Offer(
      id: '',
      ownerUsername: owner,
      coin: _coin,
      fiatCurrency: _fiat,
      paymentMethod: _paymentMethod,
      kind: _kind,
      priceEquation: _priceCtrl.text.trim(),
      minAmount: double.parse(_minCtrl.text.replaceAll(',', '.')),
      maxAmount: double.parse(_maxCtrl.text.replaceAll(',', '.')),
      createdAt: DateTime.now(),
      country: _countryCtrl.text.trim().isEmpty ? null : _countryCtrl.text.trim(),
      city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
      terms: _termsCtrl.text.trim(),
    );
    context.read<OffersBloc>().add(OfferCreated(draft));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AuthState authState = context.watch<AuthBloc>().state;
    final String owner = authState is AuthAuthenticated
        ? authState.session.user.username
        : 'guest';
    return BlocProvider<OffersBloc>(
      create: (_) => sl<OffersBloc>(),
      child: Scaffold(
        appBar: AppBar(title: Text(l.newOffer)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                DropdownButtonFormField<OfferKind>(
                  value: _kind,
                  decoration: InputDecoration(labelText: l.offerType),
                  items: const <DropdownMenuItem<OfferKind>>[
                    DropdownMenuItem(value: OfferKind.onlineSell, child: Text('Online — sell')),
                    DropdownMenuItem(value: OfferKind.onlineBuy, child: Text('Online — buy')),
                    DropdownMenuItem(value: OfferKind.localSell, child: Text('Local — sell')),
                    DropdownMenuItem(value: OfferKind.localBuy, child: Text('Local — buy')),
                  ],
                  onChanged: (OfferKind? v) => setState(() => _kind = v ?? _kind),
                ),
                const SizedBox(height: 12),
                Row(children: <Widget>[
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _coin,
                      decoration: InputDecoration(labelText: l.coin),
                      items: AppConstants.supportedCoins
                          .map((c) => DropdownMenuItem<String>(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() => _coin = v ?? _coin),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _fiat,
                      decoration: InputDecoration(labelText: l.currency),
                      items: AppConstants.supportedFiatCurrencies
                          .map((c) => DropdownMenuItem<String>(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() => _fiat = v ?? _fiat),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _paymentMethod,
                  decoration: InputDecoration(labelText: l.paymentMethod),
                  items: AppConstants.defaultPaymentMethods
                      .map((c) => DropdownMenuItem<String>(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _paymentMethod = v ?? _paymentMethod),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceCtrl,
                  decoration: InputDecoration(
                    labelText: l.priceEquation,
                    helperText: l.priceEquationHelp,
                  ),
                  validator: (v) => InputValidators.required(v, l.priceEquation),
                ),
                const SizedBox(height: 12),
                Row(children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _minCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: l.minAmount),
                      validator: InputValidators.amount,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _maxCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: l.maxAmount),
                      validator: InputValidators.amount,
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _countryCtrl,
                      decoration: InputDecoration(labelText: l.country),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cityCtrl,
                      decoration: InputDecoration(labelText: l.city),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _termsCtrl,
                  decoration: InputDecoration(labelText: l.terms),
                  minLines: 3,
                  maxLines: 6,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => _submit(context, owner),
                  child: Text(l.save),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
