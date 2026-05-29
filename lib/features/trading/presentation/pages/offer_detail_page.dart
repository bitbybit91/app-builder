import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/datasources/trading_data_source.dart';
import '../../domain/entities/offer.dart';
import '../../domain/repositories/offer_repository.dart';
import '../bloc/trade_bloc.dart';

class OfferDetailPage extends StatefulWidget {
  const OfferDetailPage({super.key, required this.offerId});
  final String offerId;

  @override
  State<OfferDetailPage> createState() => _OfferDetailPageState();
}

class _OfferDetailPageState extends State<OfferDetailPage> {
  Offer? _offer;
  double? _marketPrice;
  String? _error;
  final TextEditingController _amountCtrl = TextEditingController(text: '100');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await sl<OfferRepository>().getOffer(widget.offerId);
    result.fold(
      (failure) => setState(() => _error = failure.message),
      (offer) async {
        final price = await sl<TradingDataSource>()
            .currentMarketPrice(offer.coin, offer.fiatCurrency);
        if (!mounted) return;
        setState(() {
          _offer = offer;
          _marketPrice = price;
        });
      },
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _openTrade(BuildContext context, Offer offer, String me) {
    final double fiat = double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;
    if (fiat < offer.minAmount || fiat > offer.maxAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Amount must be between '
            '${Formatters.fiat(offer.minAmount, offer.fiatCurrency)} and '
            '${Formatters.fiat(offer.maxAmount, offer.fiatCurrency)}')),
      );
      return;
    }
    final double price = offer.computePrice(_marketPrice ?? fiat);
    final double crypto = fiat / price;
    final bool meIsBuyer = offer.type == OfferType.sell;
    final TradeBloc bloc = sl<TradeBloc>();
    bloc.add(TradeOpenRequested(
      offerId: offer.id,
      buyerUsername: meIsBuyer ? me : offer.ownerUsername,
      sellerUsername: meIsBuyer ? offer.ownerUsername : me,
      coin: offer.coin,
      fiatCurrency: offer.fiatCurrency,
      fiatAmount: fiat,
      cryptoAmount: crypto,
      paymentMethod: offer.paymentMethod,
    ));
    bloc.stream
        .firstWhere((TradeState s) => s is TradeLoaded || s is TradeError)
        .then((TradeState s) {
      if (s is TradeLoaded && mounted) {
        context.go('/trades/${s.trade.id}');
      } else if (s is TradeError && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.failure.message)));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AuthState authState = context.watch<AuthBloc>().state;
    final String me = authState is AuthAuthenticated
        ? authState.session.user.username
        : 'guest';
    final ThemeData theme = Theme.of(context);
    if (_error != null) {
      return Scaffold(appBar: AppBar(), body: Center(child: Text(_error!)));
    }
    if (_offer == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final Offer offer = _offer!;
    final double price = offer.computePrice(_marketPrice ?? 0);

    return Scaffold(
      appBar: AppBar(title: Text('${offer.coin} • ${offer.paymentMethod}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(offer.ownerUsername,
                style: theme.textTheme.titleMedium),
            subtitle: Text('${offer.ownerFeedbackScore}% • '
                '${offer.ownerTradeCount} trades'),
            trailing: TextButton(
              child: Text(l.publicProfile),
              onPressed: () => context.push('/u/${offer.ownerUsername}'),
            ),
          ),
          const Divider(),
          ListTile(
            title: Text(l.priceEquation),
            subtitle: Text('${offer.priceEquation}  '
                '→ ${Formatters.fiat(price, offer.fiatCurrency)} / ${offer.coin}'),
          ),
          ListTile(
            title: Text(l.minAmount),
            subtitle: Text(Formatters.fiat(offer.minAmount, offer.fiatCurrency)),
          ),
          ListTile(
            title: Text(l.maxAmount),
            subtitle: Text(Formatters.fiat(offer.maxAmount, offer.fiatCurrency)),
          ),
          if (offer.country != null)
            ListTile(
              title: Text(l.country),
              subtitle: Text('${offer.country!}${offer.city != null ? ' • ${offer.city!}' : ''}'),
            ),
          if (offer.terms.isNotEmpty)
            ListTile(
              title: Text(l.terms),
              subtitle: Text(offer.terms),
            ),
          const Divider(),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: '${l.amount} (${offer.fiatCurrency})',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => _openTrade(context, offer, me),
            child: Text(l.openTrade),
          ),
        ],
      ),
    );
  }
}
