import 'package:equatable/equatable.dart';

enum CryptoCurrency { xmr, btc }

class WalletEntity extends Equatable {
  final String id;
  final CryptoCurrency currency;
  final String address;
  final String balance;
  final int? syncHeight;
  final bool isLocked;

  const WalletEntity({
    required this.id,
    required this.currency,
    required this.address,
    required this.balance,
    this.syncHeight,
    this.isLocked = false,
  });

  WalletEntity copyWith({
    String? id,
    CryptoCurrency? currency,
    String? address,
    String? balance,
    int? syncHeight,
    bool? isLocked,
  }) =>
      WalletEntity(
        id: id ?? this.id,
        currency: currency ?? this.currency,
        address: address ?? this.address,
        balance: balance ?? this.balance,
        syncHeight: syncHeight ?? this.syncHeight,
        isLocked: isLocked ?? this.isLocked,
      );

  @override
  List<Object?> get props => [id, currency, address, balance, syncHeight, isLocked];

  @override
  bool get stringify => true;
}

class BalanceEntity extends Equatable {
  final String available;
  final String locked;
  final String? fiatEquivalent;

  const BalanceEntity({
    required this.available,
    required this.locked,
    this.fiatEquivalent,
  });

  BalanceEntity copyWith({
    String? available,
    String? locked,
    String? fiatEquivalent,
  }) =>
      BalanceEntity(
        available: available ?? this.available,
        locked: locked ?? this.locked,
        fiatEquivalent: fiatEquivalent ?? this.fiatEquivalent,
      );

  @override
  List<Object?> get props => [available, locked, fiatEquivalent];

  @override
  bool get stringify => true;
}
