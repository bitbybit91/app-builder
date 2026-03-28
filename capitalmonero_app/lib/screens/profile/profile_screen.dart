import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.args});
  final Map<String, dynamic>? args;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_outline,
                  color: AppColors.textMuted, size: 52),
              const SizedBox(height: 16),
              Text('Sign in to view your profile',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.login),
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Profile header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.accent,
                  child: Text(
                    user.username.isNotEmpty
                        ? user.username[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  user.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                Text(
                  '@${user.username}',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 14),
                ),
                if (user.bio != null && user.bio!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    user.bio!,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  'Member since ${_formatDate(user.createdAt)}',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stats
          Row(
            children: [
              Expanded(
                  child: _StatCard(
                      label: 'Trades',
                      value: user.completedTrades.toString())),
              const SizedBox(width: 8),
              Expanded(
                  child: _StatCard(
                      label: 'Positive',
                      value: user.positiveFeedback.toString(),
                      color: AppColors.success)),
              const SizedBox(width: 8),
              Expanded(
                  child: _StatCard(
                      label: 'Negative',
                      value: user.negativeFeedback.toString(),
                      color: AppColors.danger)),
              const SizedBox(width: 8),
              Expanded(
                  child: _StatCard(
                      label: 'Score',
                      value: '${user.feedbackScore.toStringAsFixed(0)}%',
                      color: AppColors.success)),
            ],
          ),
          const SizedBox(height: 16),

          // 2FA Status
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: user.twoFactorEnabled
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: user.twoFactorEnabled
                    ? AppColors.success.withOpacity(0.4)
                    : AppColors.warning.withOpacity(0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  user.twoFactorEnabled
                      ? Icons.verified_user
                      : Icons.security,
                  color: user.twoFactorEnabled
                      ? AppColors.success
                      : AppColors.warning,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  user.twoFactorEnabled
                      ? '2FA Enabled'
                      : '2FA Disabled',
                  style: TextStyle(
                    color: user.twoFactorEnabled
                        ? AppColors.success
                        : AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Profile'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.settings),
            icon: const Icon(Icons.settings_outlined),
            label: const Text('Settings'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
            icon: const Icon(Icons.logout, color: AppColors.danger),
            label: const Text('Logout',
                style: TextStyle(color: AppColors.danger)),
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${_monthName(dt.month)} ${dt.year}';
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.color = AppColors.textPrimary,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
