import 'package:equatable/equatable.dart';

class WalletBalance extends Equatable {
  final String currency;
  final double available;
  final double pending;
  final double total;
  final String? depositAddress;
  final DateTime updatedAt;

  const WalletBalance({
    required this.currency,
    required this.available,
    required this.pending,
    required this.total,
    this.depositAddress,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [currency, available, pending, total, updatedAt];
}
