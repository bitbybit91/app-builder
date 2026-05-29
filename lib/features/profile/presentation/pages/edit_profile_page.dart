import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/profile_bloc.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _emailCtrl;
  late TextEditingController _countryCtrl;
  late TextEditingController _languagesCtrl;
  late TextEditingController _pgpCtrl;

  @override
  void initState() {
    super.initState();
    final AuthState s = context.read<AuthBloc>().state;
    final User? u = s is AuthAuthenticated ? s.session.user : null;
    _emailCtrl = TextEditingController(text: u?.email ?? '');
    _countryCtrl = TextEditingController(text: u?.country ?? '');
    _languagesCtrl =
        TextEditingController(text: u?.languages.join(', ') ?? 'en');
    _pgpCtrl = TextEditingController(text: u?.publicPgpKey ?? '');
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _countryCtrl.dispose();
    _languagesCtrl.dispose();
    _pgpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AuthState s = context.watch<AuthBloc>().state;
    if (s is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final User u = s.session.user;
    return Scaffold(
      appBar: AppBar(title: Text(l.editProfile)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _emailCtrl,
              decoration: InputDecoration(labelText: l.email),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _countryCtrl,
              decoration: InputDecoration(labelText: l.country),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _languagesCtrl,
              decoration: InputDecoration(
                labelText: l.languages,
                helperText: 'Comma-separated, e.g. en, fr',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pgpCtrl,
              minLines: 5,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: 'PGP public key',
                hintText: '-----BEGIN PUBLIC KEY-----',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                final User updated = u.copyWith(
                  email: _emailCtrl.text.trim().isEmpty
                      ? null
                      : _emailCtrl.text.trim(),
                  country: _countryCtrl.text.trim().isEmpty
                      ? null
                      : _countryCtrl.text.trim(),
                  languages: _languagesCtrl.text
                      .split(',')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList(),
                  publicPgpKey: _pgpCtrl.text.trim().isEmpty
                      ? null
                      : _pgpCtrl.text.trim(),
                );
                context.read<ProfileBloc>().add(ProfileUpdated(updated));
                context.pop();
              },
              child: Text(l.save),
            ),
          ],
        ),
      ),
    );
  }
}
