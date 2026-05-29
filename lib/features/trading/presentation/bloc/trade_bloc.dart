import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/trade.dart';
import '../../domain/repositories/trade_repository.dart';

abstract class TradeEvent extends Equatable {
  const TradeEvent();
  @override
  List<Object?> get props => const <Object?>[];
}

class TradeLoadRequested extends TradeEvent {
  const TradeLoadRequested(this.tradeId);
  final String tradeId;
  @override
  List<Object?> get props => <Object?>[tradeId];
}

class TradeOpenRequested extends TradeEvent {
  const TradeOpenRequested({
    required this.offerId,
    required this.buyerUsername,
    required this.sellerUsername,
    required this.coin,
    required this.fiatCurrency,
    required this.fiatAmount,
    required this.cryptoAmount,
    required this.paymentMethod,
  });
  final String offerId;
  final String buyerUsername;
  final String sellerUsername;
  final String coin;
  final String fiatCurrency;
  final double fiatAmount;
  final double cryptoAmount;
  final String paymentMethod;
  @override
  List<Object?> get props => <Object?>[offerId, fiatAmount, cryptoAmount];
}

class TradeActionRequested extends TradeEvent {
  const TradeActionRequested(this.tradeId, this.action, {this.disputeReason});
  final String tradeId;
  final TradeAction action;
  final String? disputeReason;
  @override
  List<Object?> get props => <Object?>[tradeId, action, disputeReason];
}

enum TradeAction { fund, paymentSent, paymentReceived, release, cancel, dispute }

class TradeHistoryRequested extends TradeEvent {
  const TradeHistoryRequested({required this.username, this.activeOnly = false});
  final String username;
  final bool activeOnly;
  @override
  List<Object?> get props => <Object?>[username, activeOnly];
}

class TradeMessagesRequested extends TradeEvent {
  const TradeMessagesRequested(this.tradeId);
  final String tradeId;
  @override
  List<Object?> get props => <Object?>[tradeId];
}

class TradeMessageSent extends TradeEvent {
  const TradeMessageSent({
    required this.tradeId,
    required this.fromUsername,
    required this.body,
    this.encrypted = false,
  });
  final String tradeId;
  final String fromUsername;
  final String body;
  final bool encrypted;
  @override
  List<Object?> get props => <Object?>[tradeId, fromUsername, body, encrypted];
}

abstract class TradeState extends Equatable {
  const TradeState();
  @override
  List<Object?> get props => const <Object?>[];
}

class TradeInitial extends TradeState {
  const TradeInitial();
}

class TradeLoading extends TradeState {
  const TradeLoading();
}

class TradeLoaded extends TradeState {
  const TradeLoaded(this.trade, {this.messages = const <TradeMessage>[]});
  final Trade trade;
  final List<TradeMessage> messages;

  TradeLoaded copyWith({Trade? trade, List<TradeMessage>? messages}) =>
      TradeLoaded(trade ?? this.trade, messages: messages ?? this.messages);

  @override
  List<Object?> get props => <Object?>[trade, messages];
}

class TradeHistoryLoaded extends TradeState {
  const TradeHistoryLoaded(this.trades);
  final List<Trade> trades;
  @override
  List<Object?> get props => <Object?>[trades];
}

class TradeError extends TradeState {
  const TradeError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => <Object?>[failure];
}

class TradeBloc extends Bloc<TradeEvent, TradeState> {
  TradeBloc({required TradeRepository repository})
      : _repository = repository,
        super(const TradeInitial()) {
    on<TradeLoadRequested>(_onLoad);
    on<TradeOpenRequested>(_onOpen);
    on<TradeActionRequested>(_onAction);
    on<TradeHistoryRequested>(_onHistory);
    on<TradeMessagesRequested>(_onMessages);
    on<TradeMessageSent>(_onMessageSent);
  }

  final TradeRepository _repository;

  Future<void> _onLoad(TradeLoadRequested event, Emitter<TradeState> emit) async {
    emit(const TradeLoading());
    final result = await _repository.getTrade(event.tradeId);
    final messages = await _repository.messages(event.tradeId);
    result.fold(
      (failure) => emit(TradeError(failure)),
      (trade) => emit(TradeLoaded(
        trade,
        messages: messages.getOrElse(() => const <TradeMessage>[]),
      )),
    );
  }

  Future<void> _onOpen(TradeOpenRequested event, Emitter<TradeState> emit) async {
    emit(const TradeLoading());
    final result = await _repository.openTrade(
      offerId: event.offerId,
      buyerUsername: event.buyerUsername,
      sellerUsername: event.sellerUsername,
      coin: event.coin,
      fiatCurrency: event.fiatCurrency,
      fiatAmount: event.fiatAmount,
      cryptoAmount: event.cryptoAmount,
      paymentMethod: event.paymentMethod,
    );
    result.fold(
      (failure) => emit(TradeError(failure)),
      (trade) => emit(TradeLoaded(trade)),
    );
  }

  Future<void> _onAction(TradeActionRequested event, Emitter<TradeState> emit) async {
    final result = switch (event.action) {
      TradeAction.fund => await _repository.fundEscrow(event.tradeId),
      TradeAction.paymentSent => await _repository.markPaymentSent(event.tradeId),
      TradeAction.paymentReceived => await _repository.markPaymentReceived(event.tradeId),
      TradeAction.release => await _repository.releaseEscrow(event.tradeId),
      TradeAction.cancel => await _repository.cancelTrade(event.tradeId),
      TradeAction.dispute => await _repository.openDispute(
          event.tradeId, event.disputeReason ?? 'Unspecified'),
    };
    result.fold(
      (failure) => emit(TradeError(failure)),
      (trade) {
        if (state is TradeLoaded) {
          emit((state as TradeLoaded).copyWith(trade: trade));
        } else {
          emit(TradeLoaded(trade));
        }
      },
    );
  }

  Future<void> _onHistory(
      TradeHistoryRequested event, Emitter<TradeState> emit) async {
    emit(const TradeLoading());
    final result = await _repository.history(
      username: event.username,
      filter: TradeFilter(activeOnly: event.activeOnly),
    );
    result.fold(
      (failure) => emit(TradeError(failure)),
      (trades) => emit(TradeHistoryLoaded(trades)),
    );
  }

  Future<void> _onMessages(
      TradeMessagesRequested event, Emitter<TradeState> emit) async {
    final result = await _repository.messages(event.tradeId);
    result.fold(
      (failure) => emit(TradeError(failure)),
      (messages) {
        if (state is TradeLoaded) {
          emit((state as TradeLoaded).copyWith(messages: messages));
        }
      },
    );
  }

  Future<void> _onMessageSent(
      TradeMessageSent event, Emitter<TradeState> emit) async {
    final result = await _repository.sendMessage(
      tradeId: event.tradeId,
      fromUsername: event.fromUsername,
      body: event.body,
      encrypted: event.encrypted,
    );
    result.fold(
      (failure) => emit(TradeError(failure)),
      (message) {
        if (state is TradeLoaded) {
          final loaded = state as TradeLoaded;
          emit(loaded.copyWith(
            messages: <TradeMessage>[...loaded.messages, message],
          ));
        }
      },
    );
  }
}
