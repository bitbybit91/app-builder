import 'dart:math';

import 'package:uuid/uuid.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/wallet_balance.dart';

abstract class WalletDataSource {
  Future<WalletBalance> balance(String coin);
  Future<String> newDepositAddress(String coin);
  Future<WalletTransaction> withdraw({
    required String coin,
    required String destination,
    required double amount,
  });
  Future<List<WalletTransaction>> history(String coin);
}

/// Hybrid implementation.
///
/// In production this calls into:
///   * Monero RPC (`get_balance`, `get_address`, `transfer`).
///   * Electrum/Bitcoin daemon RPC (`getbalance`, `getnewaddress`,
///     `sendtoaddress`).
///
/// The current build ships an in-memory simulator that mirrors the wire
/// shapes so the UI can be exercised on a phone without a daemon.
class InMemoryWalletDataSource implements WalletDataSource {
  InMemoryWalletDataSource() {
    _balances['XMR'] = _SimulatedBalance(available: 4.32, pending: 0.0);
    _balances['BTC'] = _SimulatedBalance(available: 0.218, pending: 0.0);
    _seedHistory();
  }

  final Map<String, _SimulatedBalance> _balances = <String, _SimulatedBalance>{};
  final Map<String, List<WalletTransaction>> _history =
      <String, List<WalletTransaction>>{};
  final Uuid _uuid = const Uuid();
  final Random _rng = Random();

  void _seedHistory() {
    final DateTime now = DateTime.now();
    _history['XMR'] = <WalletTransaction>[
      WalletTransaction(
        id: _uuid.v4(),
        coin: 'XMR',
        amount: 1.20,
        direction: TxDirection.incoming,
        confirmations: 32,
        timestamp: now.subtract(const Duration(days: 1)),
        txHash: 'a14f5e...c93',
      ),
      WalletTransaction(
        id: _uuid.v4(),
        coin: 'XMR',
        amount: 0.50,
        direction: TxDirection.outgoing,
        confirmations: 18,
        timestamp: now.subtract(const Duration(hours: 6)),
        address: '4Apk...x6w',
        txHash: 'd220...a01',
      ),
    ];
    _history['BTC'] = <WalletTransaction>[
      WalletTransaction(
        id: _uuid.v4(),
        coin: 'BTC',
        amount: 0.05,
        direction: TxDirection.incoming,
        confirmations: 6,
        timestamp: now.subtract(const Duration(days: 4)),
        txHash: '7bc1...11a',
      ),
    ];
  }

  @override
  Future<WalletBalance> balance(String coin) async {
    final _SimulatedBalance? b = _balances[coin.toUpperCase()];
    if (b == null) throw WalletException('Unsupported coin: $coin');
    return WalletBalance(
      coin: coin.toUpperCase(),
      available: b.available,
      pending: b.pending,
    );
  }

  @override
  Future<String> newDepositAddress(String coin) async {
    switch (coin.toUpperCase()) {
      case 'XMR':
        return '4${_randomChars(94)}';
      case 'BTC':
        return 'bc1q${_randomChars(38).toLowerCase()}';
      default:
        throw WalletException('Unsupported coin: $coin');
    }
  }

  @override
  Future<WalletTransaction> withdraw({
    required String coin,
    required String destination,
    required double amount,
  }) async {
    final _SimulatedBalance? b = _balances[coin.toUpperCase()];
    if (b == null) throw WalletException('Unsupported coin: $coin');
    if (amount <= 0) throw ValidationException('Amount must be positive');
    if (amount > b.available) {
      throw WalletException('Insufficient balance');
    }
    b.available -= amount;
    final WalletTransaction tx = WalletTransaction(
      id: _uuid.v4(),
      coin: coin.toUpperCase(),
      amount: amount,
      direction: TxDirection.outgoing,
      confirmations: 0,
      timestamp: DateTime.now(),
      address: destination,
      txHash: _randomChars(40).toLowerCase(),
    );
    _history.putIfAbsent(coin.toUpperCase(), () => <WalletTransaction>[]).insert(0, tx);
    return tx;
  }

  @override
  Future<List<WalletTransaction>> history(String coin) async {
    return List<WalletTransaction>.unmodifiable(
      _history[coin.toUpperCase()] ?? const <WalletTransaction>[],
    );
  }

  String _randomChars(int n) {
    const String chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List<String>.generate(n, (_) => chars[_rng.nextInt(chars.length)]).join();
  }
}

class _SimulatedBalance {
  _SimulatedBalance({required this.available, required this.pending});
  double available;
  double pending;
}
