import 'package:capitalmonero/features/trading/data/datasources/trading_data_source.dart';
import 'package:capitalmonero/features/trading/data/repositories/trade_repository_impl.dart';
import 'package:capitalmonero/features/trading/domain/entities/trade.dart';
import 'package:capitalmonero/features/trading/domain/repositories/trade_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late TradingDataSource source;
  late TradeRepository repo;

  setUp(() {
    source = InMemoryTradingDataSource();
    repo = TradeRepositoryImpl(source: source);
  });

  test('escrow lifecycle moves through expected statuses', () async {
    final open = await repo.openTrade(
      offerId: 'o1',
      buyerUsername: 'alice',
      sellerUsername: 'bob',
      coin: 'XMR',
      fiatCurrency: 'USD',
      fiatAmount: 100,
      cryptoAmount: 0.6,
      paymentMethod: 'Bank',
    );
    final Trade trade = open.getOrElse(() => throw StateError('open failed'));
    expect(trade.status, TradeStatus.created);

    final funded =
        (await repo.fundEscrow(trade.id)).getOrElse(() => trade);
    expect(funded.status, TradeStatus.funded);
    expect(funded.escrowAddress, isNotNull);

    final sent =
        (await repo.markPaymentSent(trade.id)).getOrElse(() => trade);
    expect(sent.status, TradeStatus.paymentSent);

    final received =
        (await repo.markPaymentReceived(trade.id)).getOrElse(() => trade);
    expect(received.status, TradeStatus.paymentReceived);

    final released =
        (await repo.releaseEscrow(trade.id)).getOrElse(() => trade);
    expect(released.status, TradeStatus.released);
    expect(released.releasedAt, isNotNull);
  });

  test('openDispute switches status and records reason', () async {
    final open = await repo.openTrade(
      offerId: 'o1',
      buyerUsername: 'alice',
      sellerUsername: 'bob',
      coin: 'BTC',
      fiatCurrency: 'EUR',
      fiatAmount: 50,
      cryptoAmount: 0.001,
      paymentMethod: 'Cash',
    );
    final Trade trade = open.getOrElse(() => throw StateError('open failed'));
    final disputed =
        (await repo.openDispute(trade.id, 'Payment unclear'))
            .getOrElse(() => trade);
    expect(disputed.status, TradeStatus.disputed);
    expect(disputed.disputeReason, 'Payment unclear');
  });
}
