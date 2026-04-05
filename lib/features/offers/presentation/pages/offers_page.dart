import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/empty_state.dart';
import '../bloc/offers_bloc.dart';
import '../widgets/offer_card.dart';
import '../widgets/offers_filter_bar.dart';

class OffersPage extends StatelessWidget {
  const OffersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OffersBloc>()..add(const OffersLoadRequested()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Offers'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {},
            ),
          ],
        ),
        body: Column(
          children: [
            const OffersFilterBar(),
            Expanded(
              child: BlocBuilder<OffersBloc, OffersState>(
                builder: (context, state) {
                  if (state is OffersLoading) {
                    return const LoadingIndicator();
                  }
                  if (state is OffersError) {
                    return ErrorView(
                      message: state.message,
                      onRetry: () {
                        context.read<OffersBloc>().add(const OffersRefreshRequested());
                      },
                    );
                  }
                  if (state is OffersLoaded) {
                    if (state.offers.isEmpty) {
                      return const EmptyState(
                        icon: Icons.local_offer_outlined,
                        title: 'No offers found',
                        subtitle: 'Try adjusting your filters or create a new offer',
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<OffersBloc>().add(const OffersRefreshRequested());
                      },
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification is ScrollEndNotification &&
                              notification.metrics.extentAfter < 300) {
                            context.read<OffersBloc>().add(const OffersLoadMoreRequested());
                          }
                          return false;
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.offers.length + (state.hasReachedMax ? 0 : 1),
                          itemBuilder: (context, index) {
                            if (index >= state.offers.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: LoadingIndicator(size: 24),
                              );
                            }
                            final offer = state.offers[index];
                            return OfferCard(
                              offer: offer,
                              onTap: () => context.go('/offers/${offer.id}'),
                            );
                          },
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.go('/offers/create'),
          icon: const Icon(Icons.add),
          label: const Text('Create Offer'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
