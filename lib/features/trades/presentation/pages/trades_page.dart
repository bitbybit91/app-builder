import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/empty_state.dart';
import '../bloc/trades_bloc.dart';
import '../widgets/trade_card.dart';

class TradesPage extends StatelessWidget {
  const TradesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TradesBloc>()..add(const TradesLoadRequested()),
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('My Trades'),
            bottom: TabBar(
              isScrollable: true,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Active'),
                Tab(text: 'Completed'),
                Tab(text: 'Cancelled'),
              ],
              onTap: (index) {
                final statuses = [null, 'OPEN', 'COMPLETED', 'CANCELLED'];
                context.read<TradesBloc>().add(
                      TradesTabChanged(status: statuses[index]),
                    );
              },
            ),
          ),
          body: BlocBuilder<TradesBloc, TradesState>(
            builder: (context, state) {
              if (state is TradesLoading) {
                return const LoadingIndicator();
              }
              if (state is TradesError) {
                return ErrorView(
                  message: state.message,
                  onRetry: () {
                    context.read<TradesBloc>().add(const TradesRefreshRequested());
                  },
                );
              }
              if (state is TradesLoaded) {
                if (state.trades.isEmpty) {
                  return const EmptyState(
                    icon: Icons.swap_horiz,
                    title: 'No trades yet',
                    subtitle: 'Your trades will appear here',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<TradesBloc>().add(const TradesRefreshRequested());
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.trades.length,
                    itemBuilder: (context, index) {
                      final trade = state.trades[index];
                      return TradeCard(
                        trade: trade,
                        onTap: () => context.go('/trades/${trade.id}'),
                      );
                    },
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}
