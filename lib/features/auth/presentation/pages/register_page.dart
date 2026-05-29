import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/input_validators.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/mnemonic_dialog.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the terms of service')),
      );
      return;
    }
    context.read<AuthBloc>().add(AuthRegisterRequested(
          username: _usernameCtrl.text.trim(),
          password: _passwordCtrl.text,
          email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.createAccount)),
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (BuildContext context, AuthState state) async {
            if (state is AuthFailureState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.failure.message)),
              );
            } else if (state is AuthAuthenticated && state.freshMnemonic != null) {
              await showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (_) => MnemonicDialog(mnemonic: state.freshMnemonic!),
              );
              if (!context.mounted) return;
              context.read<AuthBloc>().add(const AuthMnemonicAcknowledged());
              context.go('/offers');
            }
          },
          builder: (BuildContext context, AuthState state) {
            final bool loading = state is AuthLoading;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    TextFormField(
                      controller: _usernameCtrl,
                      decoration: InputDecoration(labelText: l.username),
                      validator: InputValidators.username,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(labelText: '${l.email} (${l.optional})'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: true,
                      decoration: InputDecoration(labelText: l.password),
                      validator: InputValidators.password,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: true,
                      decoration: InputDecoration(labelText: l.confirmPassword),
                      validator: (String? v) =>
                          InputValidators.confirmPassword(v, _passwordCtrl.text),
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      value: _agreedToTerms,
                      onChanged: (bool? v) =>
                          setState(() => _agreedToTerms = v ?? false),
                      title: Text(l.acceptTerms),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: loading ? null : _submit,
                      child: Text(loading ? '...' : l.createAccount),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text(l.signIn),
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
