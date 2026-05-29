import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/wallet_balance.dart';
import '../../domain/repositories/wallet_repository.dart';

abstract class WalletEvent extends Equatable {
  const WalletEvent();
  @override
  List<Object?> get props => const <Object?>[];
}

class WalletLoadRequested extends WalletEvent {
  const WalletLoadRequested(this.coin);
  final String coin;
  @override
  List<Object?> get props => <Object?>[coin];
}

class WalletNewAddressRequested extends WalletEvent {
  const WalletNewAddressRequested(this.coin);
  final String coin;
  @override
  List<Object?> get props => <Object?>[coin];
}

class WalletWithdrawRequested extends WalletEvent {
  const WalletWithdrawRequested({
    required this.coin,
    required this.destination,
    required this.amount,
  });
  final String coin;
  final String destination;
  final double amount;
  @override
  List<Object?> get props => <Object?>[coin, destination, amount];
}

abstract class WalletState extends Equatable {
  const WalletState();
  @override
  List<Object?> get props => const <Object?>[];
}

class WalletInitial extends WalletState {
  const WalletInitial();
}

class WalletLoading extends WalletState {
  const WalletLoading();
}

class WalletLoaded extends WalletState {
  const WalletLoaded({
    required this.coin,
    required this.balance,
    required this.depositAddress,
    required this.history,
    this.lastWithdrawal,
  });
  final String coin;
  final WalletBalance balance;
  final String depositAddress;
  final List<WalletTransaction> history;
  final WalletTransaction? lastWithdrawal;

  WalletLoaded copyWith({
    WalletBalance? balance,
    String? depositAddress,
    List<WalletTransaction>? history,
    WalletTransaction? lastWithdrawal,
  }) =>
      WalletLoaded(
        coin: coin,
        balance: balance ?? this.balance,
        depositAddress: depositAddress ?? this.depositAddress,
        history: history ?? this.history,
        lastWithdrawal: lastWithdrawal ?? this.lastWithdrawal,
      );

  @override
  List<Object?> get props => <Object?>[coin, balance, depositAddress, history, lastWithdrawal];
}

class WalletError extends WalletState {
  const WalletError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => <Object?>[failure];
}

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  WalletBloc({required WalletRepository repository})
      : _repository = repository,
        super(const WalletInitial()) {
    on<WalletLoadRequested>(_onLoad);
    on<WalletNewAddressRequested>(_onNewAddress);
    on<WalletWithdrawRequested>(_onWithdraw);
  }

  final WalletRepository _repository;

  Future<void> _onLoad(WalletLoadRequested event, Emitter<WalletState> emit) async {
    emit(const WalletLoading());
    final balance = await _repository.getBalance(event.coin);
    final address = await _repository.generateDepositAddress(event.coin);
    final history = await _repository.history(event.coin);
    final WalletBalance? b = balance.fold((_) => null, (b) => b);
    final String? a = address.fold((_) => null, (a) => a);
    final List<WalletTransaction> h = history.fold((_) => const <WalletTransaction>[], (h) => h);
    if (b == null || a == null) {
      emit(WalletError(balance.fold((f) => f, (_) => address.fold((f) => f, (_) => const UnexpectedFailure()))));
      return;
    }
    emit(WalletLoaded(
      coin: event.coin,
      balance: b,
      depositAddress: a,
      history: h,
    ));
  }

  Future<void> _onNewAddress(
      WalletNewAddressRequested event, Emitter<WalletState> emit) async {
    final result = await _repository.generateDepositAddress(event.coin);
    result.fold(
      (failure) => emit(WalletError(failure)),
      (addr) {
        if (state is WalletLoaded) {
          emit((state as WalletLoaded).copyWith(depositAddress: addr));
        }
      },
    );
  }

  Future<void> _onWithdraw(
      WalletWithdrawRequested event, Emitter<WalletState> emit) async {
    final result = await _repository.withdraw(
      coin: event.coin,
      destination: event.destination,
      amount: event.amount,
    );
    result.fold(
      (failure) => emit(WalletError(failure)),
      (tx) async {
        final balance = await _repository.getBalance(event.coin);
        final WalletBalance? b = balance.fold((_) => null, (b) => b);
        if (state is WalletLoaded && b != null) {
          final loaded = state as WalletLoaded;
          emit(loaded.copyWith(
            balance: b,
            history: <WalletTransaction>[tx, ...loaded.history],
            lastWithdrawal: tx,
          ));
        }
      },
    );
  }
}
