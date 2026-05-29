import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();
  @override
  List<Object?> get props => const <Object?>[];
}

class NotificationsLoadRequested extends NotificationsEvent {
  const NotificationsLoadRequested();
}

class NotificationsMarkAllRead extends NotificationsEvent {
  const NotificationsMarkAllRead();
}

class NotificationsMarkRead extends NotificationsEvent {
  const NotificationsMarkRead(this.id);
  final String id;
  @override
  List<Object?> get props => <Object?>[id];
}

abstract class NotificationsState extends Equatable {
  const NotificationsState();
  @override
  List<Object?> get props => const <Object?>[];
}

class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

class NotificationsLoaded extends NotificationsState {
  const NotificationsLoaded(this.items);
  final List<AppNotification> items;
  int get unread => items.where((AppNotification n) => !n.read).length;
  @override
  List<Object?> get props => <Object?>[items];
}

class NotificationsErrorState extends NotificationsState {
  const NotificationsErrorState(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => <Object?>[failure];
}

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc({required NotificationsRepository repository})
      : _repository = repository,
        super(const NotificationsInitial()) {
    on<NotificationsLoadRequested>(_onLoad);
    on<NotificationsMarkAllRead>(_onMarkAllRead);
    on<NotificationsMarkRead>(_onMarkRead);
    add(const NotificationsLoadRequested());
  }

  final NotificationsRepository _repository;

  Future<void> _onLoad(
      NotificationsLoadRequested event, Emitter<NotificationsState> emit) async {
    emit(const NotificationsLoading());
    final result = await _repository.list();
    result.fold(
      (failure) => emit(NotificationsErrorState(failure)),
      (items) => emit(NotificationsLoaded(items)),
    );
  }

  Future<void> _onMarkAllRead(
      NotificationsMarkAllRead event, Emitter<NotificationsState> emit) async {
    await _repository.markAllRead();
    add(const NotificationsLoadRequested());
  }

  Future<void> _onMarkRead(
      NotificationsMarkRead event, Emitter<NotificationsState> emit) async {
    await _repository.markRead(event.id);
    add(const NotificationsLoadRequested());
  }
}
