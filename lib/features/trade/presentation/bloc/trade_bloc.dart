import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:capital_monero/core/logging/app_logger.dart';
import 'package:capital_monero/features/trade/domain/entities/trade_entity.dart';
import 'package:capital_monero/features/trade/domain/usecases/get_trade_usecase.dart';
import 'package:capital_monero/features/trade/domain/usecases/send_message_usecase.dart';
import 'package:capital_monero/features/trade/domain/usecases/update_trade_status_usecase.dart';

// Events
sealed class TradeEvent extends Equatable {
  const TradeEvent();
  @override List<Object?> get props => [];
}
final class LoadTrade extends TradeEvent {
  final String id;
  const LoadTrade(this.id);
  @override List<Object?> get props => [id];
}
final class LoadMessages extends TradeEvent {
  final String tradeId;
  const LoadMessages(this.tradeId);
  @override List<Object?> get props => [tradeId];
}
final class SendMessage extends TradeEvent {
  final String tradeId;
  final String content;
  const SendMessage({required this.tradeId, required this.content});
  @override List<Object?> get props => [tradeId, content];
}
final class UpdateStatus extends TradeEvent {
  final String tradeId;
  final TradeStatus status;
  const UpdateStatus({required this.tradeId, required this.status});
  @override List<Object?> get props => [tradeId, status];
}
final class OpenDispute extends TradeEvent {
  final String tradeId;
  final String reason;
  const OpenDispute({required this.tradeId, required this.reason});
  @override List<Object?> get props => [tradeId, reason];
}

// States
sealed class TradeState extends Equatable {
  const TradeState();
  @override List<Object?> get props => [];
}
final class TradeInitial extends TradeState { const TradeInitial(); }
final class TradeLoading extends TradeState { const TradeLoading(); }
final class TradeLoaded extends TradeState {
  final TradeEntity trade;
  final List<ChatMessage> messages;
  const TradeLoaded({required this.trade, this.messages = const []});
  @override List<Object?> get props => [trade, messages];
}
final class TradeError extends TradeState {
  final String message;
  const TradeError(this.message);
  @override List<Object?> get props => [message];
}
final class MessageSent extends TradeState {
  final ChatMessage message;
  const MessageSent(this.message);
  @override List<Object?> get props => [message];
}
final class StatusUpdated extends TradeState {
  final TradeEntity trade;
  const StatusUpdated(this.trade);
  @override List<Object?> get props => [trade];
}

// BLoC
@injectable
class TradeBloc extends Bloc<TradeEvent, TradeState> {
  static const _tag = 'TradeBloc';
  final GetTradeUseCase _getTrade;
  final SendMessageUseCase _sendMessage;
  final UpdateTradeStatusUseCase _updateStatus;

  TradeBloc(this._getTrade, this._sendMessage, this._updateStatus)
      : super(const TradeInitial()) {
    on<LoadTrade>(_onLoad);
    on<LoadMessages>(_onLoadMessages);
    on<SendMessage>(_onSend);
    on<UpdateStatus>(_onUpdateStatus);
    on<OpenDispute>(_onDispute);
  }

  Future<void> _onLoad(LoadTrade event, Emitter<TradeState> emit) async {
    AppLogger.d(_tag, 'Loading trade: ${event.id}');
    emit(const TradeLoading());
    final result = await _getTrade(event.id);
    result.fold(
      (f) { AppLogger.e(_tag, 'Load trade failed', f.message); emit(TradeError(f.message)); },
      (trade) => emit(TradeLoaded(trade: trade)),
    );
  }

  Future<void> _onLoadMessages(LoadMessages event, Emitter<TradeState> emit) async {
    // Messages are loaded alongside the trade; this is a no-op placeholder.
    AppLogger.d(_tag, 'LoadMessages: ${event.tradeId}');
  }

  Future<void> _onSend(SendMessage event, Emitter<TradeState> emit) async {
    AppLogger.d(_tag, 'Sending message in trade: ${event.tradeId}');
    final result = await _sendMessage(event.tradeId, event.content);
    result.fold(
      (f) { AppLogger.e(_tag, 'Send message failed', f.message); emit(TradeError(f.message)); },
      (msg) => emit(MessageSent(msg)),
    );
  }

  Future<void> _onUpdateStatus(UpdateStatus event, Emitter<TradeState> emit) async {
    AppLogger.d(_tag, 'Updating status: ${event.tradeId} -> ${event.status}');
    final result = await _updateStatus(event.tradeId, event.status);
    result.fold(
      (f) { AppLogger.e(_tag, 'Update status failed', f.message); emit(TradeError(f.message)); },
      (trade) => emit(StatusUpdated(trade)),
    );
  }

  void _onDispute(OpenDispute event, Emitter<TradeState> emit) {
    AppLogger.w(_tag, 'OpenDispute not yet implemented');
    emit(const TradeError('Open dispute not yet implemented'));
  }
}
