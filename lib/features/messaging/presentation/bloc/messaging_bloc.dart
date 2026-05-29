import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/messaging_repository.dart';

abstract class MessagingEvent extends Equatable {
  const MessagingEvent();
  @override
  List<Object?> get props => const <Object?>[];
}

class MessagingConversationsRequested extends MessagingEvent {
  const MessagingConversationsRequested();
}

class MessagingThreadRequested extends MessagingEvent {
  const MessagingThreadRequested(this.peerUsername);
  final String peerUsername;
  @override
  List<Object?> get props => <Object?>[peerUsername];
}

class MessagingSendRequested extends MessagingEvent {
  const MessagingSendRequested({
    required this.fromUsername,
    required this.toUsername,
    required this.body,
    this.encrypted = false,
  });
  final String fromUsername;
  final String toUsername;
  final String body;
  final bool encrypted;
  @override
  List<Object?> get props => <Object?>[fromUsername, toUsername, body, encrypted];
}

abstract class MessagingState extends Equatable {
  const MessagingState();
  @override
  List<Object?> get props => const <Object?>[];
}

class MessagingInitial extends MessagingState {
  const MessagingInitial();
}

class MessagingLoading extends MessagingState {
  const MessagingLoading();
}

class MessagingConversationsLoaded extends MessagingState {
  const MessagingConversationsLoaded(this.conversations);
  final List<Conversation> conversations;
  @override
  List<Object?> get props => <Object?>[conversations];
}

class MessagingThreadLoaded extends MessagingState {
  const MessagingThreadLoaded(this.peerUsername, this.messages);
  final String peerUsername;
  final List<DirectMessage> messages;
  MessagingThreadLoaded copyWith({List<DirectMessage>? messages}) =>
      MessagingThreadLoaded(peerUsername, messages ?? this.messages);
  @override
  List<Object?> get props => <Object?>[peerUsername, messages];
}

class MessagingError extends MessagingState {
  const MessagingError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => <Object?>[failure];
}

class MessagingBloc extends Bloc<MessagingEvent, MessagingState> {
  MessagingBloc({required MessagingRepository repository})
      : _repository = repository,
        super(const MessagingInitial()) {
    on<MessagingConversationsRequested>(_onConversations);
    on<MessagingThreadRequested>(_onThread);
    on<MessagingSendRequested>(_onSend);
  }

  final MessagingRepository _repository;

  Future<void> _onConversations(
      MessagingConversationsRequested event, Emitter<MessagingState> emit) async {
    emit(const MessagingLoading());
    final result = await _repository.conversations();
    result.fold(
      (failure) => emit(MessagingError(failure)),
      (list) => emit(MessagingConversationsLoaded(list)),
    );
  }

  Future<void> _onThread(
      MessagingThreadRequested event, Emitter<MessagingState> emit) async {
    emit(const MessagingLoading());
    final result = await _repository.thread(event.peerUsername);
    result.fold(
      (failure) => emit(MessagingError(failure)),
      (list) => emit(MessagingThreadLoaded(event.peerUsername, list)),
    );
  }

  Future<void> _onSend(
      MessagingSendRequested event, Emitter<MessagingState> emit) async {
    final result = await _repository.send(
      fromUsername: event.fromUsername,
      toUsername: event.toUsername,
      body: event.body,
      encrypted: event.encrypted,
    );
    result.fold(
      (failure) => emit(MessagingError(failure)),
      (msg) {
        if (state is MessagingThreadLoaded) {
          final loaded = state as MessagingThreadLoaded;
          emit(loaded.copyWith(messages: <DirectMessage>[...loaded.messages, msg]));
        }
      },
    );
  }
}
