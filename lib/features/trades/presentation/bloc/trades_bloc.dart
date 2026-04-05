import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/trade.dart';
import '../../domain/usecases/get_trades_usecase.dart';

part 'trades_event.dart';
part 'trades_state.dart';

class TradesBloc extends Bloc<TradesEvent, TradesState> {
  final GetTradesUseCase getTradesUseCase;

  TradesBloc({required this.getTradesUseCase}) : super(const TradesInitial()) {
    on<TradesLoadRequested>(_onLoadRequested);
    on<TradesRefreshRequested>(_onRefreshRequested);
    on<TradesTabChanged>(_onTabChanged);
  }

  String? _currentStatus;

  Future<void> _onLoadRequested(
    TradesLoadRequested event,
    Emitter<TradesState> emit,
  ) async {
    emit(const TradesLoading());
    _currentStatus = event.status;
    final result = await getTradesUseCase(
      GetTradesParams(status: event.status),
    );
    result.fold(
      (failure) => emit(TradesError(message: failure.message)),
      (trades) => emit(TradesLoaded(trades: trades)),
    );
  }

  Future<void> _onRefreshRequested(
    TradesRefreshRequested event,
    Emitter<TradesState> emit,
  ) async {
    final result = await getTradesUseCase(
      GetTradesParams(status: _currentStatus),
    );
    result.fold(
      (failure) => emit(TradesError(message: failure.message)),
      (trades) => emit(TradesLoaded(trades: trades)),
    );
  }

  Future<void> _onTabChanged(
    TradesTabChanged event,
    Emitter<TradesState> emit,
  ) async {
    add(TradesLoadRequested(status: event.status));
  }
}
