part of 'trades_bloc.dart';

abstract class TradesEvent extends Equatable {
  const TradesEvent();
  @override
  List<Object?> get props => [];
}

class TradesLoadRequested extends TradesEvent {
  final String? status;
  const TradesLoadRequested({this.status});
  @override
  List<Object?> get props => [status];
}

class TradesRefreshRequested extends TradesEvent {
  const TradesRefreshRequested();
}

class TradesTabChanged extends TradesEvent {
  final String? status;
  const TradesTabChanged({this.status});
  @override
  List<Object?> get props => [status];
}
