import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../providers/admin_provider.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: Consumer<AdminProvider>(
        builder: (context, provider, _) {
          if (provider.loading && provider.stats.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: () => provider.fetchStats(),
            color: AppColors.accent,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Dashboard',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 16),
                // Stats grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.6,
                  children: [
                    _StatCard(
                      label: 'Total Users',
                      value: provider.stats['users_count']?.toString() ?? '0',
                      icon: Icons.people_outline,
                      color: AppColors.info,
                    ),
                    _StatCard(
                      label: 'Active Offers',
                      value: provider.stats['offers_count']?.toString() ?? '0',
                      icon: Icons.list_alt_outlined,
                      color: AppColors.accent,
                    ),
                    _StatCard(
                      label: 'Total Trades',
                      value: provider.stats['trades_count']?.toString() ?? '0',
                      icon: Icons.swap_horiz,
                      color: AppColors.success,
                    ),
                    _StatCard(
                      label: 'Completed',
                      value: provider.stats['completed_trades']?.toString() ?? '0',
                      icon: Icons.check_circle_outline,
                      color: AppColors.success,
                    ),
                    _StatCard(
                      label: 'Open Disputes',
                      value: provider.stats['open_disputes']?.toString() ?? '0',
                      icon: Icons.gavel_outlined,
                      color: AppColors.danger,
                    ),
                    _StatCard(
                      label: 'Revenue',
                      value: '\$${provider.stats['revenue']?.toString() ?? '0'}',
                      icon: Icons.attach_money,
                      color: AppColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Quick Actions',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                ..._buildActions(context),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final actions = [
      _ActionItem(
        icon: Icons.people_outline,
        title: 'Manage Users',
        subtitle: 'View, ban, or unban users',
        route: AppRoutes.adminUsers,
      ),
      _ActionItem(
        icon: Icons.swap_horiz,
        title: 'Manage Trades',
        subtitle: 'View all platform trades',
        route: AppRoutes.adminTrades,
      ),
      _ActionItem(
        icon: Icons.gavel_outlined,
        title: 'Manage Disputes',
        subtitle: 'Resolve open disputes',
        route: AppRoutes.adminDisputes,
      ),
      _ActionItem(
        icon: Icons.settings_outlined,
        title: 'Platform Settings',
        subtitle: 'Configure platform settings',
        route: AppRoutes.adminSettings,
      ),
    ];

    return actions
        .map(
          (a) => Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(a.icon, color: AppColors.accent, size: 22),
              ),
              title: Text(a.title),
              subtitle: Text(a.subtitle),
              trailing: const Icon(Icons.chevron_right,
                  color: AppColors.textMuted),
              onTap: () => Navigator.pushNamed(context, a.route),
            ),
          ),
        )
        .toList();
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
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
        ],
      ),
    );
  }
}

class _ActionItem {
  const _ActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
}
