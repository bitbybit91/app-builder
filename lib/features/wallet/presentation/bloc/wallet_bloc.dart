import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/usecases/get_wallet_usecase.dart';

// Events
abstract class WalletEvent extends Equatable {
  const WalletEvent();
  @override
  List<Object?> get props => [];
}

class LoadWallet extends WalletEvent {
  final String coinType;
  const LoadWallet(this.coinType);
  @override
  List<Object?> get props => [coinType];
}

class RefreshBalance extends WalletEvent {
  final String coinType;
  const RefreshBalance(this.coinType);
  @override
  List<Object?> get props => [coinType];
}

// States
abstract class WalletState extends Equatable {
  const WalletState();
  @override
  List<Object?> get props => [];
}

class WalletInitial extends WalletState {}
class WalletLoading extends WalletState {}

class WalletLoaded extends WalletState {
  final Wallet wallet;
  final List<WalletTransaction> transactions;
  const WalletLoaded({required this.wallet, this.transactions = const []});
  @override
  List<Object?> get props => [wallet, transactions];
}

class WalletError extends WalletState {
  final String message;
  const WalletError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final GetWalletUseCase getWalletUseCase;

  WalletBloc({required this.getWalletUseCase}) : super(WalletInitial()) {
    on<LoadWallet>(_onLoadWallet);
    on<RefreshBalance>(_onRefreshBalance);
  }

  Future<void> _onLoadWallet(LoadWallet event, Emitter<WalletState> emit) async {
    emit(WalletLoading());
    try {
      final wallet = await getWalletUseCase(event.coinType);
      emit(WalletLoaded(wallet: wallet));
    } catch (e) {
      emit(WalletError(e.toString()));
    }
  }

  Future<void> _onRefreshBalance(RefreshBalance event, Emitter<WalletState> emit) async {
    try {
      final wallet = await getWalletUseCase(event.coinType);
      emit(WalletLoaded(wallet: wallet));
    } catch (e) {
      emit(WalletError(e.toString()));
    }
  }
}
