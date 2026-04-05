part of 'wallet_bloc.dart';

abstract class WalletEvent extends Equatable {
  const WalletEvent();
  @override
  List<Object?> get props => [];
}

class WalletLoadRequested extends WalletEvent {
  const WalletLoadRequested();
}

class WalletRefreshRequested extends WalletEvent {
  const WalletRefreshRequested();
}
