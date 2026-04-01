import 'package:equatable/equatable.dart';

class Wallet extends Equatable {
  final String id;
  final String coinType;
  final double balance;
  final double pendingBalance;
  final String depositAddress;
  final DateTime lastUpdated;

  const Wallet({
    required this.id,
    required this.coinType,
    required this.balance,
    required this.pendingBalance,
    required this.depositAddress,
    required this.lastUpdated,
  });

  double get totalBalance => balance + pendingBalance;

  @override
  List<Object?> get props => [id, coinType, balance, pendingBalance];
}
