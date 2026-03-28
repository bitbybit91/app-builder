import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../services/biometric_service.dart';
import '../../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _torMode;
  late bool _biometricEnabled;
  late String _preferredCurrency;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    final storage = StorageService.instance;
    _torMode = storage.getTorMode();
    _biometricEnabled = storage.getBiometricEnabled();
    _preferredCurrency = storage.getPreferredCurrency();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final available = await BiometricService.instance.isAvailable();
    if (mounted) setState(() => _biometricAvailable = available);
  }

  Future<void> _pickCurrency() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Select Currency'),
        backgroundColor: AppColors.bgSecondary,
        children: FiatCurrencies.all
            .map(
              (c) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, c),
                child: Text(
                  '$c — ${FiatCurrencies.names[c] ?? c}',
                  style: TextStyle(
                    color: c == _preferredCurrency
                        ? AppColors.accent
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
    if (selected != null) {
      await StorageService.instance.setPreferredCurrency(selected);
      if (mounted) setState(() => _preferredCurrency = selected);
    }
  }

  Future<void> _clearCache() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cache cleared')),
    );
  }

  Future<void> _changePassword() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change Password'),
        content: const Text('Password change is available in the web dashboard.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Privacy & Security
          _SectionHeader('Privacy & Security'),
          SwitchListTile(
            secondary: const Icon(Icons.vpn_lock_outlined),
            title: const Text('Tor Mode'),
            subtitle: const Text('Route traffic through Tor network'),
            value: _torMode,
            onChanged: (v) async {
              await StorageService.instance.setTorMode(v);
              setState(() => _torMode = v);
            },
          ),
          if (_biometricAvailable)
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: const Text('Biometric Lock'),
              subtitle: const Text('Use biometrics to unlock app'),
              value: _biometricEnabled,
              onChanged: (v) async {
                if (v) {
                  final auth = await BiometricService.instance
                      .authenticate(reason: 'Enable biometric lock');
                  if (!auth) return;
                }
                await StorageService.instance.setBiometricEnabled(v);
                if (mounted) setState(() => _biometricEnabled = v);
              },
            ),
          const Divider(),

          // Preferences
          _SectionHeader('Preferences'),
          ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: const Text('Preferred Currency'),
            trailing: Text(
              _preferredCurrency,
              style: const TextStyle(color: AppColors.accent),
            ),
            onTap: _pickCurrency,
          ),
          const Divider(),

          // Two-Factor Auth
          _SectionHeader('Two-Factor Authentication'),
          if (auth.user != null && !auth.user!.twoFactorEnabled)
            ListTile(
              leading: const Icon(Icons.security,
                  color: AppColors.warning),
              title: const Text('Enable 2FA',
                  style: TextStyle(color: AppColors.warning)),
              subtitle: const Text('Secure your account'),
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.twoFactorSetup),
            )
          else if (auth.user != null && auth.user!.twoFactorEnabled)
            ListTile(
              leading: const Icon(Icons.verified_user,
                  color: AppColors.success),
              title: const Text('2FA Enabled'),
              subtitle: const Text('Your account is protected'),
              trailing: TextButton(
                onPressed: () async {
                  final pwd = await _showPasswordDialog();
                  if (pwd != null && pwd.isNotEmpty) {
                    await auth.disableTwoFactor(pwd);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(auth.error ?? '2FA disabled'),
                        backgroundColor: auth.error != null
                            ? AppColors.danger
                            : AppColors.success,
                      ),
                    );
                  }
                },
                child: const Text('Disable',
                    style: TextStyle(color: AppColors.danger)),
              ),
            ),
          const Divider(),

          // Account
          _SectionHeader('Account'),
          ListTile(
            leading: const Icon(Icons.lock_outlined),
            title: const Text('Change Password'),
            onTap: _changePassword,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Push Notifications'),
            value: true,
            onChanged: (_) {},
          ),
          const Divider(),

          // App
          _SectionHeader('App'),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: const Text('Clear Cache'),
            onTap: _clearCache,
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App Version'),
            trailing: Text(
              AppConstants.appVersion,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          const Divider(),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.danger),
            title: const Text('Logout',
                style: TextStyle(color: AppColors.danger)),
            onTap: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<String?> _showPasswordDialog() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Password'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Your password'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, ctrl.text),
              child: const Text('Confirm')),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
