import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trade_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TradeProvider>().fetchTrades(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final trades = context.watch<TradeProvider>();
    final user = auth.user;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Welcome header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.accent.withOpacity(0.15),
                  AppColors.bgCard,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accent.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.accent,
                  child: Text(
                    user.username.isNotEmpty
                        ? user.username[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        '@${user.username}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Completed',
                  value: user.completedTrades.toString(),
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: 'Positive',
                  value: user.positiveFeedback.toString(),
                  icon: Icons.thumb_up_outlined,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: 'Negative',
                  value: user.negativeFeedback.toString(),
                  icon: Icons.thumb_down_outlined,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2FA Status Card
          if (!user.twoFactorEnabled)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security,
                      color: AppColors.warning, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '2FA Disabled',
                          style: TextStyle(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600),
                        ),
                        const Text(
                          'Enable two-factor authentication to secure your account',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(
                        context, AppRoutes.twoFactorSetup),
                    child: const Text('Enable'),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withOpacity(0.5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user,
                      color: AppColors.success, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Two-Factor Authentication Enabled',
                    style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Quick actions
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.add_circle_outline,
                  label: 'Create Offer',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.offersCreate),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: Icons.list_alt_outlined,
                  label: 'Browse Offers',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.offers),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Wallet',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.wallet),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Recent trades
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Trades',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.trades),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (trades.loading && trades.trades.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (trades.trades.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Icon(Icons.swap_horiz,
                      color: AppColors.textMuted, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'No trades yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                ],
              ),
            )
          else
            ...trades.trades.take(5).map(
                  (trade) => _TradeListItem(
                    tradeId: trade.tradeId,
                    crypto: trade.crypto,
                    fiatAmount: trade.fiatAmount,
                    fiatCurrency: trade.fiatCurrency,
                    status: trade.status,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.tradeDetail,
                      arguments: {'trade_id': trade.tradeId},
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.accent, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TradeListItem extends StatelessWidget {
  const _TradeListItem({
    required this.tradeId,
    required this.crypto,
    required this.fiatAmount,
    required this.fiatCurrency,
    required this.status,
    required this.onTap,
  });
  final String tradeId;
  final String crypto;
  final double fiatAmount;
  final String fiatCurrency;
  final String status;
  final VoidCallback onTap;

  Color get _statusColor {
    switch (status) {
      case TradeStatus.completed:
        return AppColors.success;
      case TradeStatus.disputed:
        return AppColors.warning;
      case TradeStatus.cancelled:
      case TradeStatus.expired:
        return AppColors.danger;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.bgInput,
          child: Text(
            crypto,
            style: const TextStyle(
                color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text('Trade #${tradeId.substring(0, 8)}...'),
        subtitle: Text(
          '$fiatCurrency ${fiatAmount.toStringAsFixed(2)}',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _statusColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status.toUpperCase(),
            style: TextStyle(
                color: _statusColor, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
