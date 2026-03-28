import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/admin_provider.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchUsers(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final p = context.read<AdminProvider>();
      if (!p.loading && p.hasMoreUsers) {
        p.fetchUsers(search: _searchController.text.trim());
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _banUser(int userId) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Ban User'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(labelText: 'Ban reason'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(context, ctrl.text),
              child: const Text('Ban'),
            ),
          ],
        );
      },
    );
    if (reason != null && reason.isNotEmpty) {
      await context.read<AdminProvider>().banUser(userId, reason);
    }
  }

  Future<void> _unbanUser(int userId) async {
    await context.read<AdminProvider>().unbanUser(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search users...',
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (v) {
                context
                    .read<AdminProvider>()
                    .fetchUsers(search: v, refresh: true);
              },
            ),
          ),
          Expanded(
            child: Consumer<AdminProvider>(
              builder: (context, provider, _) {
                if (provider.loading && provider.adminUsers.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.adminUsers.isEmpty) {
                  return const Center(
                    child: Text('No users found',
                        style: TextStyle(color: AppColors.textMuted)),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => provider.fetchUsers(
                      search: _searchController.text, refresh: true),
                  color: AppColors.accent,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: provider.adminUsers.length +
                        (provider.hasMoreUsers ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == provider.adminUsers.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                                color: AppColors.accent),
                          ),
                        );
                      }
                      final user = provider.adminUsers[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.bgInput,
                            child: Text(
                              user.username[0].toUpperCase(),
                              style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(user.username),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.email,
                                  style: const TextStyle(fontSize: 12)),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: user.isBanned
                                          ? AppColors.danger.withOpacity(0.15)
                                          : AppColors.success.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      user.isBanned ? 'BANNED' : 'ACTIVE',
                                      style: TextStyle(
                                        color: user.isBanned
                                            ? AppColors.danger
                                            : AppColors.success,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (user.isAdmin) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent
                                            .withOpacity(0.15),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'ADMIN',
                                        style: TextStyle(
                                          color: AppColors.accent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          trailing: user.isBanned
                              ? TextButton(
                                  onPressed: () => _unbanUser(user.id),
                                  child: const Text('Unban',
                                      style: TextStyle(
                                          color: AppColors.success)),
                                )
                              : TextButton(
                                  onPressed: () => _banUser(user.id),
                                  child: const Text('Ban',
                                      style: TextStyle(
                                          color: AppColors.danger)),
                                ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
