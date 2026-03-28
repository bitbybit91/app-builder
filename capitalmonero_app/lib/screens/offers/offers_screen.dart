import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/app_theme.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../models/offer.dart';
import '../../providers/auth_provider.dart';
import '../../providers/offer_provider.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key, this.args});
  final Map<String, dynamic>? args;

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  final _scrollController = ScrollController();
  String? _filterType;
  String? _filterCurrency;
  String? _filterPayment;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OfferProvider>().fetchOffers(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<OfferProvider>();
      if (!provider.loading && provider.hasMore) {
        provider.fetchOffers();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    context.read<OfferProvider>().setFilter(
          type: _filterType,
          currency: _filterCurrency,
          paymentMethod: _filterPayment,
        );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Filter Offers',
                  style: Theme.of(ctx).textTheme.headlineMedium),
              const SizedBox(height: 20),
              const Text('Type', style: TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final t in ['buy', 'sell'])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(t.toUpperCase()),
                        selected: _filterType == t,
                        onSelected: (s) =>
                            setModalState(() => _filterType = s ? t : null),
                      ),
                    ),
                  ChoiceChip(
                    label: const Text('ALL'),
                    selected: _filterType == null,
                    onSelected: (s) =>
                        setModalState(() => _filterType = null),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Currency',
                  style: TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _filterCurrency,
                decoration: const InputDecoration(hintText: 'All currencies'),
                dropdownColor: AppColors.bgCard,
                items: [
                  const DropdownMenuItem<String>(
                      value: null, child: Text('All')),
                  ...FiatCurrencies.all.map(
                    (c) => DropdownMenuItem<String>(
                        value: c, child: Text(c)),
                  ),
                ],
                onChanged: (v) =>
                    setModalState(() => _filterCurrency = v),
              ),
              const SizedBox(height: 16),
              const Text('Payment Method',
                  style: TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _filterPayment,
                decoration:
                    const InputDecoration(hintText: 'All methods'),
                dropdownColor: AppColors.bgCard,
                items: [
                  const DropdownMenuItem<String>(
                      value: null, child: Text('All')),
                  ...PaymentMethods.all.map(
                    (p) => DropdownMenuItem<String>(
                        value: p, child: Text(p)),
                  ),
                ],
                onChanged: (v) =>
                    setModalState(() => _filterPayment = v),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _applyFilters();
                },
                child: const Text('Apply Filters'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('P2P Offers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      floatingActionButton: auth.isLoggedIn
          ? FloatingActionButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.offersCreate),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          // Filter chips row
          if (_filterType != null ||
              _filterCurrency != null ||
              _filterPayment != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  if (_filterType != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Chip(
                        label: Text(_filterType!.toUpperCase()),
                        onDeleted: () {
                          setState(() => _filterType = null);
                          _applyFilters();
                        },
                      ),
                    ),
                  if (_filterCurrency != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Chip(
                        label: Text(_filterCurrency!),
                        onDeleted: () {
                          setState(() => _filterCurrency = null);
                          _applyFilters();
                        },
                      ),
                    ),
                  if (_filterPayment != null)
                    Chip(
                      label: Text(_filterPayment!),
                      onDeleted: () {
                        setState(() => _filterPayment = null);
                        _applyFilters();
                      },
                    ),
                ],
              ),
            ),
          Expanded(
            child: Consumer<OfferProvider>(
              builder: (context, provider, _) {
                if (provider.loading && provider.offers.isEmpty) {
                  return _ShimmerList();
                }
                if (provider.error != null && provider.offers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.danger, size: 40),
                        const SizedBox(height: 12),
                        Text(provider.error!,
                            style: const TextStyle(
                                color: AppColors.textMuted)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              provider.fetchOffers(refresh: true),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                if (provider.offers.isEmpty) {
                  return const Center(
                    child: Text('No offers found',
                        style: TextStyle(color: AppColors.textMuted)),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      provider.fetchOffers(refresh: true),
                  color: AppColors.accent,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: provider.offers.length +
                        (provider.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == provider.offers.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                                color: AppColors.accent),
                          ),
                        );
                      }
                      return _OfferCard(
                        offer: provider.offers[index],
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.offerDetail,
                          arguments: {'offer_id': provider.offers[index].id},
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

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.offer, required this.onTap});
  final Offer offer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isBuy = offer.type == 'buy';
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
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (isBuy ? AppColors.success : AppColors.danger)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isBuy ? 'BUY' : 'SELL',
                      style: TextStyle(
                        color: isBuy
                            ? AppColors.success
                            : AppColors.danger,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.bgInput,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      offer.crypto,
                      style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Spacer(),
                  if (offer.user != null)
                    Text(
                      '@${offer.user!.username}',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Price',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 11)),
                      Text(
                        offer.priceType == 'fixed' && offer.fixedPrice != null
                            ? '${offer.fiatCurrency} ${offer.fixedPrice!.toStringAsFixed(2)}'
                            : '${offer.priceMargin?.toStringAsFixed(1) ?? '0'}% market',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Limits',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 11)),
                      Text(
                        '${offer.fiatCurrency} ${offer.minAmount.toStringAsFixed(0)} – ${offer.maxAmount.toStringAsFixed(0)}',
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.payment, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    offer.paymentMethod,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                  ),
                  const Spacer(),
                  const Icon(Icons.access_time,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${offer.paymentWindow} min',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShimmerList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 6,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Shimmer.fromColors(
          baseColor: AppColors.bgCard,
          highlightColor: AppColors.bgInput,
          child: Container(
            height: 110,
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
