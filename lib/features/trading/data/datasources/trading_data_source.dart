import 'dart:async';
import 'dart:math';

import 'package:uuid/uuid.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/offer.dart';
import '../../domain/entities/trade.dart';

abstract class TradingDataSource {
  Future<List<Offer>> listOffers({
    String? coin,
    String? fiatCurrency,
    String? paymentMethod,
    OfferType? type,
    String? country,
    int page = 1,
    int pageSize = 20,
    String sortBy = 'price',
  });
  Future<Offer> getOffer(String id);
  Future<Offer> createOffer(Offer offer);
  Future<Offer> updateOffer(Offer offer);
  Future<void> deleteOffer(String id);
  Future<List<Offer>> myOffers(String username);

  Future<Trade> openTrade(Trade draft);
  Future<Trade> getTrade(String id);
  Future<List<Trade>> tradeHistory(String username, {bool activeOnly = false});
  Future<Trade> updateTrade(Trade trade);
  Future<List<TradeMessage>> messages(String tradeId);
  Future<TradeMessage> postMessage(TradeMessage msg);

  /// Mock market price feed; used by [Offer.computePrice] consumers.
  Future<double> currentMarketPrice(String coin, String fiat);
}

class InMemoryTradingDataSource implements TradingDataSource {
  InMemoryTradingDataSource() {
    _seed();
  }

  final Uuid _uuid = const Uuid();
  final List<Offer> _offers = <Offer>[];
  final Map<String, Trade> _trades = <String, Trade>{};
  final Map<String, List<TradeMessage>> _messages = <String, List<TradeMessage>>{};

  void _seed() {
    final DateTime now = DateTime.now();
    _offers.addAll(<Offer>[
      Offer(
        id: _uuid.v4(),
        ownerUsername: 'satoshi',
        coin: 'XMR',
        fiatCurrency: 'USD',
        paymentMethod: 'Bank transfer',
        kind: OfferKind.onlineSell,
        priceEquation: 'market*1.02',
        minAmount: 50,
        maxAmount: 2000,
        createdAt: now.subtract(const Duration(hours: 4)),
        country: 'US',
        terms: 'Pay within 30 minutes.',
        ownerFeedbackScore: 99,
        ownerTradeCount: 312,
      ),
      Offer(
        id: _uuid.v4(),
        ownerUsername: 'alice',
        coin: 'XMR',
        fiatCurrency: 'EUR',
        paymentMethod: 'SEPA',
        kind: OfferKind.onlineSell,
        priceEquation: 'market*1.015',
        minAmount: 100,
        maxAmount: 5000,
        createdAt: now.subtract(const Duration(hours: 1)),
        country: 'DE',
        terms: 'Same-name SEPA only.',
        ownerFeedbackScore: 100,
        ownerTradeCount: 47,
      ),
      Offer(
        id: _uuid.v4(),
        ownerUsername: 'bob',
        coin: 'BTC',
        fiatCurrency: 'USD',
        paymentMethod: 'Cash in person',
        kind: OfferKind.localSell,
        priceEquation: 'market*1.05',
        minAmount: 200,
        maxAmount: 10000,
        createdAt: now.subtract(const Duration(hours: 8)),
        country: 'US',
        city: 'Austin',
        terms: 'Public location only.',
        ownerFeedbackScore: 92,
        ownerTradeCount: 18,
      ),
      Offer(
        id: _uuid.v4(),
        ownerUsername: 'kovri',
        coin: 'XMR',
        fiatCurrency: 'JPY',
        paymentMethod: 'Wise',
        kind: OfferKind.onlineBuy,
        priceEquation: 'market*0.99',
        minAmount: 10000,
        maxAmount: 200000,
        createdAt: now.subtract(const Duration(days: 1)),
        country: 'JP',
        ownerFeedbackScore: 100,
        ownerTradeCount: 220,
      ),
    ]);
  }

  @override
  Future<List<Offer>> listOffers({
    String? coin,
    String? fiatCurrency,
    String? paymentMethod,
    OfferType? type,
    String? country,
    int page = 1,
    int pageSize = 20,
    String sortBy = 'price',
  }) async {
    Iterable<Offer> filtered = _offers.where((Offer o) => o.isActive);
    if (coin != null) {
      filtered = filtered.where((Offer o) => o.coin == coin);
    }
    if (fiatCurrency != null) {
      filtered = filtered.where((Offer o) => o.fiatCurrency == fiatCurrency);
    }
    if (paymentMethod != null) {
      filtered =
          filtered.where((Offer o) => o.paymentMethod == paymentMethod);
    }
    if (type != null) {
      filtered = filtered.where((Offer o) => o.type == type);
    }
    if (country != null) {
      filtered = filtered.where((Offer o) => o.country == country);
    }
    final List<Offer> list = filtered.toList();
    switch (sortBy) {
      case 'recency':
        list.sort((Offer a, Offer b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'reputation':
        list.sort((Offer a, Offer b) =>
            b.ownerFeedbackScore.compareTo(a.ownerFeedbackScore));
        break;
      case 'price':
      default:
        list.sort((Offer a, Offer b) => a.priceEquation.compareTo(b.priceEquation));
    }
    final int start = (page - 1) * pageSize;
    if (start >= list.length) return <Offer>[];
    final int end = min(start + pageSize, list.length);
    return list.sublist(start, end);
  }

  @override
  Future<Offer> getOffer(String id) async {
    final Offer? found = _offers.where((Offer o) => o.id == id).cast<Offer?>()
        .firstWhere((Offer? _) => true, orElse: () => null);
    if (found == null) throw NotFoundException('Offer $id not found');
    return found;
  }

  @override
  Future<Offer> createOffer(Offer offer) async {
    final Offer withId = Offer(
      id: _uuid.v4(),
      ownerUsername: offer.ownerUsername,
      coin: offer.coin,
      fiatCurrency: offer.fiatCurrency,
      paymentMethod: offer.paymentMethod,
      kind: offer.kind,
      priceEquation: offer.priceEquation,
      minAmount: offer.minAmount,
      maxAmount: offer.maxAmount,
      createdAt: DateTime.now(),
      country: offer.country,
      city: offer.city,
      terms: offer.terms,
      requireVerifiedEmail: offer.requireVerifiedEmail,
      requireMinTrades: offer.requireMinTrades,
      isActive: true,
    );
    _offers.add(withId);
    return withId;
  }

  @override
  Future<Offer> updateOffer(Offer offer) async {
    final int idx = _offers.indexWhere((Offer o) => o.id == offer.id);
    if (idx < 0) throw NotFoundException('Offer ${offer.id}');
    _offers[idx] = offer;
    return offer;
  }

  @override
  Future<void> deleteOffer(String id) async {
    _offers.removeWhere((Offer o) => o.id == id);
  }

  @override
  Future<List<Offer>> myOffers(String username) async {
    return _offers.where((Offer o) => o.ownerUsername == username).toList();
  }

  @override
  Future<Trade> openTrade(Trade draft) async {
    final Trade withId = Trade(
      id: _uuid.v4(),
      offerId: draft.offerId,
      buyerUsername: draft.buyerUsername,
      sellerUsername: draft.sellerUsername,
      coin: draft.coin,
      fiatCurrency: draft.fiatCurrency,
      fiatAmount: draft.fiatAmount,
      cryptoAmount: draft.cryptoAmount,
      paymentMethod: draft.paymentMethod,
      status: TradeStatus.created,
      createdAt: DateTime.now(),
    );
    _trades[withId.id] = withId;
    return withId;
  }

  @override
  Future<Trade> getTrade(String id) async {
    final Trade? t = _trades[id];
    if (t == null) throw NotFoundException('Trade $id');
    return t;
  }

  @override
  Future<List<Trade>> tradeHistory(String username,
      {bool activeOnly = false}) async {
    return _trades.values
        .where((Trade t) =>
            t.buyerUsername == username || t.sellerUsername == username)
        .where((Trade t) => activeOnly ? t.isActive : true)
        .toList()
      ..sort((Trade a, Trade b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<Trade> updateTrade(Trade trade) async {
    if (!_trades.containsKey(trade.id)) {
      throw NotFoundException('Trade ${trade.id}');
    }
    _trades[trade.id] = trade;
    return trade;
  }

  @override
  Future<List<TradeMessage>> messages(String tradeId) async {
    return List<TradeMessage>.unmodifiable(
        _messages[tradeId] ?? const <TradeMessage>[]);
  }

  @override
  Future<TradeMessage> postMessage(TradeMessage msg) async {
    final TradeMessage stored = TradeMessage(
      id: _uuid.v4(),
      tradeId: msg.tradeId,
      fromUsername: msg.fromUsername,
      body: msg.body,
      sentAt: DateTime.now(),
      encrypted: msg.encrypted,
    );
    _messages.putIfAbsent(msg.tradeId, () => <TradeMessage>[]).add(stored);
    return stored;
  }

  @override
  Future<double> currentMarketPrice(String coin, String fiat) async {
    // Stable mock prices so the UI is deterministic in the demo build.
    const Map<String, double> base = <String, double>{
      'XMR': 165.42,
      'BTC': 64321.18,
    };
    const Map<String, double> fiatMul = <String, double>{
      'USD': 1.0,
      'EUR': 0.92,
      'GBP': 0.78,
      'JPY': 156.0,
      'CNY': 7.25,
      'KRW': 1380.0,
      'CHF': 0.90,
      'AUD': 1.52,
      'CAD': 1.36,
      'SEK': 10.45,
      'NOK': 10.65,
      'DKK': 6.85,
    };
    final double coinPrice = base[coin] ?? 1.0;
    final double mul = fiatMul[fiat] ?? 1.0;
    return coinPrice * mul;
  }
}
