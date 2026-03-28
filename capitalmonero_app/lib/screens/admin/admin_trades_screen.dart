import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../providers/admin_provider.dart';

class AdminTradesScreen extends StatefulWidget {
  const AdminTradesScreen({super.key});

  @override
  State<AdminTradesScreen> createState() => _AdminTradesScreenState();
}

class _AdminTradesScreenState extends State<AdminTradesScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchAdminTrades(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final p = context.read<AdminProvider>();
      if (!p.loading && p.hasMoreTrades) p.fetchAdminTrades();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
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
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Trades')),
      body: Consumer<AdminProvider>(
        builder: (context, provider, _) {
          if (provider.loading && provider.adminTrades.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.adminTrades.isEmpty) {
            return const Center(
              child: Text('No trades found',
                  style: TextStyle(color: AppColors.textMuted)),
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.fetchAdminTrades(refresh: true),
            color: AppColors.accent,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: provider.adminTrades.length +
                  (provider.hasMoreTrades ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == provider.adminTrades.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                          color: AppColors.accent),
                    ),
                  );
                }
                final trade = provider.adminTrades[index];
                return Card(
                  child: ListTile(
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.tradeDetail,
                      arguments: {'trade_id': trade.tradeId},
                    ),
                    title: Text(
                      'Trade #${trade.tradeId.substring(0, 10)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${trade.cryptoAmount.toStringAsFixed(6)} ${trade.crypto} · ${trade.fiatCurrency} ${trade.fiatAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12),
                        ),
                        Text(
                          'Buyer: @${trade.buyer?.username ?? 'unknown'} · Seller: @${trade.seller?.username ?? 'unknown'}',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusColor(trade.status).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        trade.status.toUpperCase().replaceAll('_', ' '),
                        style: TextStyle(
                          color: _statusColor(trade.status),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
