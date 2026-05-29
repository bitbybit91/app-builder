import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/offer.dart';
import '../../domain/repositories/offer_repository.dart';
import '../bloc/offers_bloc.dart';

class OffersPage extends StatelessWidget {
  const OffersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return BlocProvider<OffersBloc>(
      create: (_) => sl<OffersBloc>()..add(const OffersLoadRequested()),
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.offers),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => context.push('/offers/new'),
              tooltip: l.createOffer,
            ),
          ],
        ),
        body: BlocBuilder<OffersBloc, OffersState>(
          builder: (BuildContext context, OffersState state) {
            if (state is OffersLoading || state is OffersInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is OffersError) {
              return Center(child: Text(state.failure.message));
            }
            final List<Offer> offers = (state as OffersLoaded).offers;
            if (offers.isEmpty) {
              return _EmptyState(
                title: l.noOffersTitle,
                subtitle: l.noOffersHint,
              );
            }
            return RefreshIndicator(
              onRefresh: () async => context
                  .read<OffersBloc>()
                  .add(const OffersRefreshRequested()),
              child: ListView.separated(
                padding: const EdgeInsets.all(8),
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemCount: offers.length,
                itemBuilder: (BuildContext context, int i) =>
                    _OfferTile(offer: offers[i]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OfferTile extends StatelessWidget {
  const _OfferTile({required this.offer});
  final Offer offer;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final bool isSell = offer.type == OfferType.sell;
    final Color tagColor = isSell
        ? Colors.orange.shade400
        : Theme.of(context).colorScheme.primary;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/offers/${offer.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: tagColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${isSell ? l.sell : l.buy} ${offer.coin}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: tagColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    offer.isLocal ? l.local : l.online,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${offer.ownerUsername} • ${offer.paymentMethod}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  Text(
                    '${offer.priceEquation} ${offer.fiatCurrency}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  Text(
                    '${Formatters.fiat(offer.minAmount, offer.fiatCurrency)} – '
                    '${Formatters.fiat(offer.maxAmount, offer.fiatCurrency)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  Icon(Icons.verified_user_outlined,
                      size: 14,
                      color: Theme.of(context).colorScheme.outline),
                  const SizedBox(width: 4),
                  Text('${offer.ownerFeedbackScore}% • ${offer.ownerTradeCount} trades',
                      style: Theme.of(context).textTheme.bodySmall),
                  const Spacer(),
                  if (offer.country != null)
                    Text(offer.country!,
                        style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.inbox_outlined, size: 64),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// Keep the analyzer happy when the file is imported but no offers list is shown.
// ignore: unused_element
typedef _Unused = OfferRepository;
