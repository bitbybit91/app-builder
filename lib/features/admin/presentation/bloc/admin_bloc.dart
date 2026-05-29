import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/repositories/admin_repository.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();
  @override
  List<Object?> get props => const <Object?>[];
}

class AdminLoadRequested extends AdminEvent {
  const AdminLoadRequested();
}

class AdminUserModerated extends AdminEvent {
  const AdminUserModerated({required this.username, required this.action});
  final String username;
  final UserModerationAction action;
  @override
  List<Object?> get props => <Object?>[username, action];
}

abstract class AdminState extends Equatable {
  const AdminState();
  @override
  List<Object?> get props => const <Object?>[];
}

class AdminInitial extends AdminState {
  const AdminInitial();
}

class AdminLoading extends AdminState {
  const AdminLoading();
}

class AdminLoaded extends AdminState {
  const AdminLoaded({required this.users, required this.stats});
  final List<User> users;
  final PlatformStats stats;
  @override
  List<Object?> get props => <Object?>[users, stats];
}

class AdminErrorState extends AdminState {
  const AdminErrorState(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => <Object?>[failure];
}

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  AdminBloc({required AdminRepository repository})
      : _repository = repository,
        super(const AdminInitial()) {
    on<AdminLoadRequested>(_onLoad);
    on<AdminUserModerated>(_onModerate);
  }

  final AdminRepository _repository;

  Future<void> _onLoad(AdminLoadRequested event, Emitter<AdminState> emit) async {
    emit(const AdminLoading());
    final users = await _repository.listUsers();
    final stats = await _repository.stats();
    final List<User>? u = users.fold((_) => null, (u) => u);
    final PlatformStats? s = stats.fold((_) => null, (s) => s);
    if (u == null || s == null) {
      emit(AdminErrorState(users.fold((f) => f, (_) => const UnexpectedFailure())));
      return;
    }
    emit(AdminLoaded(users: u, stats: s));
  }

  Future<void> _onModerate(
      AdminUserModerated event, Emitter<AdminState> emit) async {
    await _repository.moderateUser(username: event.username, action: event.action);
    add(const AdminLoadRequested());
  }
}
