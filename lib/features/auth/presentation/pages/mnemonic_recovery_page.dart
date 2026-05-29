import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/input_validators.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/auth_bloc.dart';

class MnemonicRecoveryPage extends StatefulWidget {
  const MnemonicRecoveryPage({super.key});

  @override
  State<MnemonicRecoveryPage> createState() => _MnemonicRecoveryPageState();
}

class _MnemonicRecoveryPageState extends State<MnemonicRecoveryPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _mnemonicCtrl = TextEditingController();
  final TextEditingController _newPasswordCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _mnemonicCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(AuthRecoverRequested(
          mnemonic: _mnemonicCtrl.text.trim(),
          newPassword: _newPasswordCtrl.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.recoverAccount)),
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (BuildContext context, AuthState state) {
            if (state is AuthFailureState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.failure.message)),
              );
            } else if (state is AuthAuthenticated) {
              context.go('/offers');
            }
          },
          builder: (BuildContext context, AuthState state) {
            final bool loading = state is AuthLoading;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(l.recoveryInstructions,
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _mnemonicCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(labelText: l.mnemonicPhrase),
                      validator: InputValidators.mnemonic,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _newPasswordCtrl,
                      obscureText: true,
                      decoration: InputDecoration(labelText: l.newPassword),
                      validator: InputValidators.password,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: true,
                      decoration: InputDecoration(labelText: l.confirmPassword),
                      validator: (String? v) =>
                          InputValidators.confirmPassword(v, _newPasswordCtrl.text),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: loading ? null : _submit,
                      child: Text(loading ? '...' : l.recoverAccount),
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
}
