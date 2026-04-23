import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:capital_monero/core/logging/app_logger.dart';
import 'package:capital_monero/features/notifications/domain/entities/notification_entity.dart';
import 'package:capital_monero/features/notifications/domain/repositories/notification_repository.dart';

// Events
sealed class NotificationsEvent extends Equatable {
  const NotificationsEvent();
  @override List<Object?> get props => [];
}
final class LoadNotifications extends NotificationsEvent { const LoadNotifications(); }
final class MarkRead extends NotificationsEvent {
  final String id;
  const MarkRead(this.id);
  @override List<Object?> get props => [id];
}
final class MarkAllRead extends NotificationsEvent { const MarkAllRead(); }
final class SetupPush extends NotificationsEvent { const SetupPush(); }

// States
sealed class NotificationsState extends Equatable {
  const NotificationsState();
  @override List<Object?> get props => [];
}
final class NotificationsInitial extends NotificationsState { const NotificationsInitial(); }
final class NotificationsLoading extends NotificationsState { const NotificationsLoading(); }
final class NotificationsLoaded extends NotificationsState {
  final List<NotificationEntity> notifications;
  final int unreadCount;
  const NotificationsLoaded({required this.notifications, required this.unreadCount});
  @override List<Object?> get props => [notifications, unreadCount];
}
final class NotificationsError extends NotificationsState {
  final String message;
  const NotificationsError(this.message);
  @override List<Object?> get props => [message];
}

// BLoC
@injectable
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  static const _tag = 'NotificationsBloc';
  final NotificationRepository _repository;
  StreamSubscription<List<NotificationEntity>>? _pollSubscription;

  NotificationsBloc(this._repository) : super(const NotificationsInitial()) {
    on<LoadNotifications>(_onLoad);
    on<MarkRead>(_onMarkRead);
    on<MarkAllRead>(_onMarkAllRead);
    on<SetupPush>(_onSetupPush);
  }

  Future<void> _onLoad(LoadNotifications event, Emitter<NotificationsState> emit) async {
    AppLogger.d(_tag, 'Loading notifications');
    emit(const NotificationsLoading());
    final result = await _repository.getNotifications();
    result.fold(
      (f) { AppLogger.e(_tag, 'Load failed', f.message); emit(NotificationsError(f.message)); },
      (list) => emit(NotificationsLoaded(
        notifications: list,
        unreadCount: list.where((n) => !n.isRead).length,
      )),
    );
  }

  Future<void> _onMarkRead(MarkRead event, Emitter<NotificationsState> emit) async {
    AppLogger.d(_tag, 'Marking read: ${event.id}');
    final result = await _repository.markAsRead(event.id);
    result.fold(
      (f) { AppLogger.e(_tag, 'Mark read failed', f.message); emit(NotificationsError(f.message)); },
      (_) => add(const LoadNotifications()),
    );
  }

  Future<void> _onMarkAllRead(MarkAllRead event, Emitter<NotificationsState> emit) async {
    AppLogger.d(_tag, 'Marking all read');
    final result = await _repository.markAllRead();
    result.fold(
      (f) { AppLogger.e(_tag, 'Mark all read failed', f.message); emit(NotificationsError(f.message)); },
      (_) => add(const LoadNotifications()),
    );
  }

  Future<void> _onSetupPush(SetupPush event, Emitter<NotificationsState> emit) async {
    AppLogger.d(_tag, 'Setting up push notifications');
    final result = await _repository.setupPushNotifications();
    result.fold(
      (f) => AppLogger.e(_tag, 'Push setup failed', f.message),
      (_) => AppLogger.d(_tag, 'Push notifications configured'),
    );
  }

  @override
  Future<void> close() {
    _pollSubscription?.cancel();
    return super.close();
  }
}
