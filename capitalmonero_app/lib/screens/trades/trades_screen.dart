import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../models/trade.dart';
import '../../providers/trade_provider.dart';

class TradesScreen extends StatefulWidget {
  const TradesScreen({super.key});

  @override
  State<TradesScreen> createState() => _TradesScreenState();
}

class _TradesScreenState extends State<TradesScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TradeProvider>().fetchTrades(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final p = context.read<TradeProvider>();
      if (!p.loading && p.hasMore) p.fetchTrades();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Trades')),
      body: Consumer<TradeProvider>(
        builder: (context, provider, _) {
          if (provider.loading && provider.trades.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null && provider.trades.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.danger, size: 40),
                  const SizedBox(height: 12),
                  Text(provider.error!,
                      style:
                          const TextStyle(color: AppColors.textMuted)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        provider.fetchTrades(refresh: true),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (provider.trades.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.swap_horiz,
                      color: AppColors.textMuted, size: 52),
                  const SizedBox(height: 16),
                  Text(
                    'No trades yet',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Browse offers to start trading',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.offers),
                    child: const Text('Browse Offers'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.fetchTrades(refresh: true),
            color: AppColors.accent,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: provider.trades.length +
                  (provider.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == provider.trades.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                          color: AppColors.accent),
                    ),
                  );
                }
                return _TradeCard(
                  trade: provider.trades[index],
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.tradeDetail,
                    arguments: {
                      'trade_id': provider.trades[index].tradeId
                    },
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

class _TradeCard extends StatelessWidget {
  const _TradeCard({required this.trade, required this.onTap});
  final Trade trade;
  final VoidCallback onTap;

  Color get _statusColor {
    switch (trade.status) {
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Trade #${trade.tradeId.substring(0, 8)}...',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      trade.status.toUpperCase().replaceAll('_', ' '),
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Amount',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 11)),
                        Text(
                          '${trade.cryptoAmount.toStringAsFixed(6)} ${trade.crypto}',
                          style: const TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Value',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 11)),
                        Text(
                          '${trade.fiatCurrency} ${trade.fiatAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (trade.buyer != null || trade.seller != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person_outline,
                        size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      'Buyer: @${trade.buyer?.username ?? 'unknown'} · Seller: @${trade.seller?.username ?? 'unknown'}',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
