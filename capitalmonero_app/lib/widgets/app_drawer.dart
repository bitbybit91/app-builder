import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:capitalmonero_app/config/app_theme.dart';
import 'package:capitalmonero_app/providers/auth_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    String initials = 'U';
    if (user != null && user.username.isNotEmpty) {
      initials = user.username.substring(0, 1).toUpperCase();
    }

    return Drawer(
      backgroundColor: AppColors.bgSecondary,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.bgPrimary,
              border: Border(
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.accent,
                      child: Text(
                        'CM',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'CapitalMonero',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // User info
                if (user != null) ...[
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.accent,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              user.username,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              user.email,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerItem(
                  icon: Icons.home_outlined,
                  label: 'Home',
                  onTap: () => _navigate(context, '/home'),
                ),
                _DrawerItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  onTap: () => _navigate(context, '/dashboard'),
                ),
                _DrawerItem(
                  icon: Icons.search,
                  label: 'Browse Offers',
                  onTap: () => _navigate(context, '/offers'),
                ),
                _DrawerItem(
                  icon: Icons.swap_horiz,
                  label: 'My Trades',
                  onTap: () => _navigate(context, '/trades'),
                ),
                _DrawerItem(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Wallet',
                  onTap: () => _navigate(context, '/wallet'),
                ),
                _DrawerItem(
                  icon: Icons.person_outline,
                  label: 'Profile',
                  onTap: () => _navigate(context, '/profile'),
                ),
                _DrawerItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () => _navigate(context, '/settings'),
                ),
                if (auth.isAdmin) ...[
                  const Divider(color: AppColors.border, height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      'ADMIN',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  _DrawerItem(
                    icon: Icons.admin_panel_settings_outlined,
                    label: 'Admin Dashboard',
                    onTap: () => _navigate(context, '/admin'),
                  ),
                ],
              ],
            ),
          ),
          const Divider(color: AppColors.border, height: 1),
          _DrawerItem(
            icon: Icons.logout,
            label: 'Logout',
            iconColor: AppColors.danger,
            labelColor: AppColors.danger,
            onTap: () async {
              Navigator.of(context).pop();
              await context.read<AuthProvider>().logout();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, String route) {
    Navigator.of(context).pop();
    Navigator.of(context).pushNamed(route);
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.textMuted, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: labelColor ?? AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      dense: true,
      horizontalTitleGap: 8,
    );
  }
}
