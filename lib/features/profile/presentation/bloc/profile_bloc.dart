import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/repositories/profile_repository.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => const <Object?>[];
}

class ProfileLoadRequested extends ProfileEvent {
  const ProfileLoadRequested(this.username);
  final String username;
  @override
  List<Object?> get props => <Object?>[username];
}

class ProfileUpdated extends ProfileEvent {
  const ProfileUpdated(this.user);
  final User user;
  @override
  List<Object?> get props => <Object?>[user];
}

abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => const <Object?>[];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  const ProfileLoaded(this.user, {this.feedback = const <Feedback>[]});
  final User user;
  final List<Feedback> feedback;
  @override
  List<Object?> get props => <Object?>[user, feedback];
}

class ProfileError extends ProfileState {
  const ProfileError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => <Object?>[failure];
}

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({required ProfileRepository repository})
      : _repository = repository,
        super(const ProfileInitial()) {
    on<ProfileLoadRequested>(_onLoad);
    on<ProfileUpdated>(_onUpdate);
  }

  final ProfileRepository _repository;

  Future<void> _onLoad(ProfileLoadRequested event, Emitter<ProfileState> emit) async {
    emit(const ProfileLoading());
    final user = await _repository.publicProfile(event.username);
    final feedback = await _repository.feedback(event.username);
    user.fold(
      (failure) => emit(ProfileError(failure)),
      (u) => emit(ProfileLoaded(
        u,
        feedback: feedback.getOrElse(() => const <Feedback>[]),
      )),
    );
  }

  Future<void> _onUpdate(ProfileUpdated event, Emitter<ProfileState> emit) async {
    final result = await _repository.update(event.user);
    result.fold(
      (failure) => emit(ProfileError(failure)),
      (u) {
        if (state is ProfileLoaded) {
          emit(ProfileLoaded(u, feedback: (state as ProfileLoaded).feedback));
        } else {
          emit(ProfileLoaded(u));
        }
      },
    );
  }
}
