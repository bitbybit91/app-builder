import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CapitalMonero'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications), onPressed: () => context.go('/notifications')),
          IconButton(icon: const Icon(Icons.person), onPressed: () => context.go('/profile/me')),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildOffersTab(),
          _buildTradesTab(),
          _buildWalletTab(),
          _buildSettingsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/create-offer'),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.store), label: 'Offers'),
          NavigationDestination(icon: Icon(Icons.swap_horiz), label: 'Trades'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildOffersTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store, size: 64, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text('Browse Offers', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Find the best deals on XMR and BTC'),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.go('/search'),
            icon: const Icon(Icons.search),
            label: const Text('Search Offers'),
          ),
        ],
      ),
    );
  }

  Widget _buildTradesTab() {
    return const Center(child: Text('Active Trades'));
  }

  Widget _buildWalletTab() {
    return Center(
      child: FilledButton.icon(
        onPressed: () => context.go('/wallet'),
        icon: const Icon(Icons.account_balance_wallet),
        label: const Text('Open Wallet'),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.message),
          title: const Text('Messages'),
          onTap: () => context.go('/messages'),
        ),
        ListTile(
          leading: const Icon(Icons.admin_panel_settings),
          title: const Text('Admin Dashboard'),
          onTap: () => context.go('/admin'),
        ),
      ],
    );
  }
}
