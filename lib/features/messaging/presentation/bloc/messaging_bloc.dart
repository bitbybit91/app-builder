import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/usecases/get_conversations_usecase.dart';

// Events
abstract class MessagingEvent extends Equatable {
  const MessagingEvent();
  @override
  List<Object?> get props => [];
}

class LoadConversations extends MessagingEvent {}

// States
abstract class MessagingState extends Equatable {
  const MessagingState();
  @override
  List<Object?> get props => [];
}

class MessagingInitial extends MessagingState {}
class MessagingLoading extends MessagingState {}

class MessagingLoaded extends MessagingState {
  final List<Conversation> conversations;
  const MessagingLoaded(this.conversations);
  @override
  List<Object?> get props => [conversations];
}

class MessagingError extends MessagingState {
  final String message;
  const MessagingError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class MessagingBloc extends Bloc<MessagingEvent, MessagingState> {
  final GetConversationsUseCase getConversationsUseCase;

  MessagingBloc({required this.getConversationsUseCase}) : super(MessagingInitial()) {
    on<LoadConversations>(_onLoadConversations);
  }

  Future<void> _onLoadConversations(LoadConversations event, Emitter<MessagingState> emit) async {
    emit(MessagingLoading());
    try {
      final conversations = await getConversationsUseCase();
      emit(MessagingLoaded(conversations));
    } catch (e) {
      emit(MessagingError(e.toString()));
    }
  }
}
