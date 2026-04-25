import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:capital_monero/core/logging/app_logger.dart';
import 'package:capital_monero/features/wallet/domain/entities/wallet_entity.dart';
import 'package:capital_monero/features/wallet/domain/usecases/get_balance_usecase.dart';
import 'package:capital_monero/features/wallet/domain/usecases/get_wallet_address_usecase.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

sealed class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object?> get props => [];
}

final class LoadWallet extends WalletEvent {
  final CryptoCurrency currency;

  const LoadWallet(this.currency);

  @override
  List<Object?> get props => [currency];
}

final class RefreshBalance extends WalletEvent {
  const RefreshBalance();
}

final class SendTransaction extends WalletEvent {
  final String toAddress;
  final String amount;

  const SendTransaction({required this.toAddress, required this.amount});

  @override
  List<Object?> get props => [toAddress, amount];
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

sealed class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object?> get props => [];
}

final class WalletInitial extends WalletState {
  const WalletInitial();
}

final class WalletLoading extends WalletState {
  const WalletLoading();
}

final class WalletLoaded extends WalletState {
  final BalanceEntity xmrBalance;
  final BalanceEntity btcBalance;
  final String xmrAddress;
  final String btcAddress;

  const WalletLoaded({
    required this.xmrBalance,
    required this.btcBalance,
    required this.xmrAddress,
    required this.btcAddress,
  });

  @override
  List<Object?> get props => [xmrBalance, btcBalance, xmrAddress, btcAddress];
}

final class WalletError extends WalletState {
  final String message;

  const WalletError(this.message);

  @override
  List<Object?> get props => [message];
}

final class TransactionSent extends WalletState {
  final String txId;

  const TransactionSent(this.txId);

  @override
  List<Object?> get props => [txId];
}

// ---------------------------------------------------------------------------
// BLoC
// ---------------------------------------------------------------------------

@injectable
class WalletBloc extends Bloc<WalletEvent, WalletState> {
  static const _tag = 'WalletBloc';

  final GetBalanceUseCase _getBalance;
  final GetWalletAddressUseCase _getWalletAddress;

  WalletBloc(this._getBalance, this._getWalletAddress)
      : super(const WalletInitial()) {
    on<LoadWallet>(_onLoad);
    on<RefreshBalance>(_onRefresh);
    on<SendTransaction>(_onSend);
  }

  Future<void> _onLoad(LoadWallet event, Emitter<WalletState> emit) async {
    AppLogger.d(_tag, 'Loading wallet for ${event.currency}');
    emit(const WalletLoading());
    await _loadWalletData(emit);
  }

  Future<void> _onRefresh(
    RefreshBalance event,
    Emitter<WalletState> emit,
  ) async {
    AppLogger.d(_tag, 'Refreshing balances');
    await _loadWalletData(emit);
  }

  Future<void> _onSend(
    SendTransaction event,
    Emitter<WalletState> emit,
  ) async {
    AppLogger.w(_tag, 'SendTransaction not yet implemented');
    emit(const WalletError('Send transaction not yet implemented'));
  }

  Future<void> _loadWalletData(Emitter<WalletState> emit) async {
    final xmrBalanceResult = await _getBalance(CryptoCurrency.xmr);
    if (xmrBalanceResult.isLeft()) {
      final msg = xmrBalanceResult.fold((f) => f.message, (_) => 'Unknown error');
      AppLogger.e(_tag, 'XMR balance failed', msg);
      emit(WalletError(msg));
      return;
    }

    final btcBalanceResult = await _getBalance(CryptoCurrency.btc);
    if (btcBalanceResult.isLeft()) {
      final msg = btcBalanceResult.fold((f) => f.message, (_) => 'Unknown error');
      AppLogger.e(_tag, 'BTC balance failed', msg);
      emit(WalletError(msg));
      return;
    }

    final xmrAddressResult = await _getWalletAddress(CryptoCurrency.xmr);
    if (xmrAddressResult.isLeft()) {
      final msg = xmrAddressResult.fold((f) => f.message, (_) => 'Unknown error');
      AppLogger.e(_tag, 'XMR address failed', msg);
      emit(WalletError(msg));
      return;
    }

    final btcAddressResult = await _getWalletAddress(CryptoCurrency.btc);
    if (btcAddressResult.isLeft()) {
      final msg = btcAddressResult.fold((f) => f.message, (_) => 'Unknown error');
      AppLogger.e(_tag, 'BTC address failed', msg);
      emit(WalletError(msg));
      return;
    }

    emit(
      WalletLoaded(
        xmrBalance: xmrBalanceResult.getOrElse(
          () => const BalanceEntity(available: '0.0000', locked: '0.0000'),
        ),
        btcBalance: btcBalanceResult.getOrElse(
          () => const BalanceEntity(available: '0.0000', locked: '0.0000'),
        ),
        xmrAddress: xmrAddressResult.getOrElse(() => ''),
        btcAddress: btcAddressResult.getOrElse(() => ''),
      ),
    );
  }
}
