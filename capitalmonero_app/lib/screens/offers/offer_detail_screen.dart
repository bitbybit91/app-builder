import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../models/offer.dart';
import '../../providers/auth_provider.dart';
import '../../providers/offer_provider.dart';
import '../../providers/trade_provider.dart';

class OfferDetailScreen extends StatefulWidget {
  const OfferDetailScreen({super.key, required this.args});
  final Map<String, dynamic> args;

  @override
  State<OfferDetailScreen> createState() => _OfferDetailScreenState();
}

class _OfferDetailScreenState extends State<OfferDetailScreen> {
  final _amountController = TextEditingController();
  Offer? _offer;

  @override
  void initState() {
    super.initState();
    final offer = widget.args['offer'] as Offer?;
    final offerId = widget.args['offer_id'] as int?;
    if (offer != null) {
      _offer = offer;
    } else if (offerId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await context.read<OfferProvider>().fetchOffer(offerId);
        if (mounted) {
          setState(() {
            _offer = context.read<OfferProvider>().selectedOffer;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _startTrade() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }
    if (_offer == null) return;

    final trade = await context.read<TradeProvider>().startTrade(
          _offer!.id,
          amount,
        );
    if (!mounted) return;
    if (trade != null) {
      Navigator.pushNamed(
        context,
        AppRoutes.tradeDetail,
        arguments: {'trade_id': trade.tradeId},
      );
    } else {
      final err = context.read<TradeProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Failed to start trade')),
      );
    }
  }

  Future<void> _deleteOffer() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Offer'),
        content: const Text(
            'Are you sure you want to delete this offer? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true && _offer != null) {
      final success =
          await context.read<OfferProvider>().deleteOffer(_offer!.id);
      if (!mounted) return;
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offer deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final offerProvider = context.watch<OfferProvider>();
    final offer = _offer ?? offerProvider.selectedOffer;

    if (offerProvider.loading && offer == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (offer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Offer')),
        body: const Center(child: Text('Offer not found')),
      );
    }

    final isBuy = offer.type == 'buy';
    final isOwner = auth.user?.id == offer.userId;
    final tradeProvider = context.watch<TradeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('${isBuy ? 'Buy' : 'Sell'} ${offer.crypto}'),
        actions: [
          if (isOwner) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.danger),
              onPressed: _deleteOffer,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Offer header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: (isBuy
                                  ? AppColors.success
                                  : AppColors.danger)
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isBuy ? 'BUY' : 'SELL',
                          style: TextStyle(
                            color: isBuy
                                ? AppColors.success
                                : AppColors.danger,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.bgInput,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          offer.crypto,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(
                    label: 'Price',
                    value: offer.priceType == 'fixed' &&
                            offer.fixedPrice != null
                        ? '${offer.fiatCurrency} ${offer.fixedPrice!.toStringAsFixed(2)}'
                        : '${offer.priceMargin?.toStringAsFixed(2) ?? '0'}% above market',
                  ),
                  _InfoRow(
                    label: 'Payment Method',
                    value: offer.paymentMethod,
                  ),
                  _InfoRow(
                    label: 'Payment Window',
                    value: '${offer.paymentWindow} minutes',
                  ),
                  _InfoRow(
                    label: 'Limits',
                    value:
                        '${offer.fiatCurrency} ${offer.minAmount.toStringAsFixed(2)} – ${offer.maxAmount.toStringAsFixed(2)}',
                  ),
                ],
              ),
            ),

            // Terms
            if (offer.terms != null && offer.terms!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Trade Terms',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Text(
                      offer.terms!,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],

            // Seller info
            if (offer.user != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.bgInput,
                      child: Text(
                        offer.user!.username[0].toUpperCase(),
                        style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '@${offer.user!.username}',
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${offer.user!.completedTrades} trades · ${offer.user!.feedbackScore.toStringAsFixed(0)}% positive',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // Start trade section (non-owner only)
            if (!isOwner && auth.isLoggedIn) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Start Trade',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: InputDecoration(
                        labelText:
                            'Amount in ${offer.fiatCurrency}',
                        prefixIcon:
                            const Icon(Icons.attach_money),
                        helperText:
                            'Min: ${offer.minAmount.toStringAsFixed(2)} · Max: ${offer.maxAmount.toStringAsFixed(2)}',
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (tradeProvider.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          tradeProvider.error!,
                          style: const TextStyle(
                              color: AppColors.danger, fontSize: 13),
                        ),
                      ),
                    ElevatedButton(
                      onPressed: tradeProvider.loading
                          ? null
                          : _startTrade,
                      child: tradeProvider.loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white),
                            )
                          : const Text('Start Trade'),
                    ),
                  ],
                ),
              ),
            ] else if (!auth.isLoggedIn) ...[
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.login),
                child: const Text('Sign in to trade'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
