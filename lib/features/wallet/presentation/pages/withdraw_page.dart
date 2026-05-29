import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/input_validators.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/wallet_bloc.dart';

class WithdrawPage extends StatefulWidget {
  const WithdrawPage({super.key, required this.coin});
  final String coin;

  @override
  State<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _addressCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('${l.withdraw} ${widget.coin}')),
      body: BlocConsumer<WalletBloc, WalletState>(
        listener: (BuildContext context, WalletState state) {
          if (state is WalletError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.failure.message)),
            );
          } else if (state is WalletLoaded && state.lastWithdrawal != null) {
            context.pop();
          }
        },
        builder: (BuildContext context, WalletState state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextFormField(
                    controller: _addressCtrl,
                    decoration: InputDecoration(labelText: l.destinationAddress),
                    validator: (v) =>
                        InputValidators.cryptoAddress(v, widget.coin),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: l.amount),
                    validator: InputValidators.amount,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) return;
                      context.read<WalletBloc>().add(WalletWithdrawRequested(
                            coin: widget.coin,
                            destination: _addressCtrl.text.trim(),
                            amount: double.parse(
                                _amountCtrl.text.replaceAll(',', '.')),
                          ));
                    },
                    child: Text(l.send),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
