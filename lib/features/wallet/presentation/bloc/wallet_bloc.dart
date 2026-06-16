import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/wallet_balance.dart';
import '../../domain/usecases/get_wallet_balances_usecase.dart';

part 'wallet_event.dart';
part 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final GetWalletBalancesUseCase getWalletBalancesUseCase;

  WalletBloc({required this.getWalletBalancesUseCase})
      : super(const WalletInitial()) {
    on<WalletLoadRequested>(_onLoadRequested);
    on<WalletRefreshRequested>(_onRefreshRequested);
  }

  Future<void> _onLoadRequested(
    WalletLoadRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(const WalletLoading());
    final result = await getWalletBalancesUseCase(const NoParams());
    result.fold(
      (failure) => emit(WalletError(message: failure.message)),
      (balances) => emit(WalletLoaded(balances: balances)),
    );
  }

  Future<void> _onRefreshRequested(
    WalletRefreshRequested event,
    Emitter<WalletState> emit,
  ) async {
    final result = await getWalletBalancesUseCase(const NoParams());
    result.fold(
      (failure) => emit(WalletError(message: failure.message)),
      (balances) => emit(WalletLoaded(balances: balances)),
    );
  }
}
