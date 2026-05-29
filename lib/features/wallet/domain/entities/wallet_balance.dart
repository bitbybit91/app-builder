import 'package:equatable/equatable.dart';

class WalletBalance extends Equatable {
  const WalletBalance({
    required this.coin,
    required this.available,
    required this.pending,
    this.fiatValue,
    this.fiatCurrency,
  });

  final String coin;
  final double available;
  final double pending;
  final double? fiatValue;
  final String? fiatCurrency;

  double get total => available + pending;

  @override
  List<Object?> get props => <Object?>[coin, available, pending, fiatValue, fiatCurrency];
}

class WalletTransaction extends Equatable {
  const WalletTransaction({
    required this.id,
    required this.coin,
    required this.amount,
    required this.direction,
    required this.confirmations,
    required this.timestamp,
    this.address,
    this.txHash,
  });

  final String id;
  final String coin;
  final double amount;
  final TxDirection direction;
  final int confirmations;
  final DateTime timestamp;
  final String? address;
  final String? txHash;

  @override
  List<Object?> get props =>
      <Object?>[id, coin, amount, direction, confirmations, timestamp, address, txHash];
}

enum TxDirection { incoming, outgoing }
