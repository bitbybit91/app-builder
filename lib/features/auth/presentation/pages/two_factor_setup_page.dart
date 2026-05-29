import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/security/totp_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/repositories/auth_repository.dart';

class TwoFactorSetupPage extends StatefulWidget {
  const TwoFactorSetupPage({super.key});

  @override
  State<TwoFactorSetupPage> createState() => _TwoFactorSetupPageState();
}

class _TwoFactorSetupPageState extends State<TwoFactorSetupPage> {
  late String _secret;
  final TextEditingController _codeCtrl = TextEditingController();
  String? _status;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _secret = sl<TotpService>().generateSecret();
  }

  Uri get _otpUri => sl<TotpService>().buildUri(
        secret: _secret,
        account: 'capitalmonero',
        issuer: 'CapitalMonero',
      );

  Future<void> _confirm() async {
    setState(() => _busy = true);
    final result = await sl<AuthRepository>().confirmTwoFactor(
      secret: _secret,
      code: _codeCtrl.text.trim(),
    );
    setState(() {
      _busy = false;
      _status = result.fold(
        (failure) => failure.message,
        (_) => 'Two-factor authentication enabled',
      );
    });
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.twoFactorSetup)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(l.twoFactorSetupIntro),
            const SizedBox(height: 16),
            Center(
              child: QrImageView(
                data: _otpUri.toString(),
                size: 220,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            SelectableText(
              _secret,
              textAlign: TextAlign.center,
              style: const TextStyle(letterSpacing: 2, fontFamily: 'monospace'),
            ),
            TextButton.icon(
              onPressed: () => Clipboard.setData(ClipboardData(text: _secret)),
              icon: const Icon(Icons.copy),
              label: Text(l.copySecret),
            ),
            const Divider(height: 32),
            TextField(
              controller: _codeCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(labelText: l.twoFactorCode),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy ? null : _confirm,
              child: Text(_busy ? '...' : l.confirm),
            ),
            if (_status != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(_status!, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}
