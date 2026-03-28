import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';

class TwoFactorSetupScreen extends StatefulWidget {
  const TwoFactorSetupScreen({super.key});

  @override
  State<TwoFactorSetupScreen> createState() => _TwoFactorSetupScreenState();
}

class _TwoFactorSetupScreenState extends State<TwoFactorSetupScreen> {
  final _codeController = TextEditingController();
  String? _secret;
  String? _qrUrl;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _loadSecret();
  }

  Future<void> _loadSecret() async {
    final auth = context.read<AuthProvider>();
    final data = await auth.enableTwoFactor();
    if (!mounted) return;
    setState(() {
      _secret = data['secret'] as String? ?? auth.twoFactorSecret;
      _qrUrl = data['qr_url'] as String? ?? auth.twoFactorQrUrl;
      _initializing = false;
    });
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a 6-digit code')),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final success = await auth.verifyTwoFactor(code);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Two-factor authentication enabled!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.settings);
    }
  }

  void _copySecret() {
    if (_secret != null) {
      Clipboard.setData(ClipboardData(text: _secret!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Secret key copied to clipboard')),
      );
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text('Setup 2FA'),
      ),
      body: _initializing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Scan QR Code',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scan this QR code from your authenticator app (e.g. Google Authenticator, Authy)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _qrUrl != null
                        ? QrImageView(
                            data: _qrUrl!,
                            size: 200,
                            backgroundColor: Colors.white,
                          )
                        : _secret != null
                            ? QrImageView(
                                data: _secret!,
                                size: 200,
                                backgroundColor: Colors.white,
                              )
                            : const SizedBox(
                                width: 200,
                                height: 200,
                                child: Center(
                                  child: Text(
                                    'QR code unavailable',
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                ),
                              ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Or enter the secret key manually:',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  if (_secret != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: SelectableText(
                              _secret!,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                color: AppColors.accent,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy,
                                color: AppColors.textMuted),
                            onPressed: _copySecret,
                            tooltip: 'Copy secret key',
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 24),
                  Text(
                    'Enter Verification Code',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'After scanning, enter the 6-digit code from your app:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return Column(
                        children: [
                          if (auth.error != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.danger),
                              ),
                              child: Text(
                                auth.error!,
                                style: const TextStyle(
                                    color: AppColors.danger, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          SizedBox(
                            width: 220,
                            child: TextField(
                              controller: _codeController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                letterSpacing: 6,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              decoration: const InputDecoration(
                                counterText: '',
                                hintText: '000000',
                                hintStyle: TextStyle(
                                  color: AppColors.textMuted,
                                  letterSpacing: 6,
                                  fontSize: 24,
                                ),
                              ),
                              onSubmitted: (_) => _verify(),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: 220,
                            child: ElevatedButton(
                              onPressed: auth.loading ? null : _verify,
                              child: auth.loading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Verify & Enable'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
