import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:capital_monero/core/logging/app_logger.dart';
import 'package:capital_monero/features/profile/domain/entities/profile_entity.dart';
import 'package:capital_monero/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:capital_monero/features/profile/domain/usecases/get_own_profile_usecase.dart';
import 'package:capital_monero/features/profile/domain/usecases/get_feedback_usecase.dart';

// Events
sealed class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override List<Object?> get props => [];
}
final class LoadProfile extends ProfileEvent {
  final String? userId;
  const LoadProfile({this.userId});
  @override List<Object?> get props => [userId];
}
final class LoadFeedback extends ProfileEvent {
  final String userId;
  const LoadFeedback(this.userId);
  @override List<Object?> get props => [userId];
}

// States
sealed class ProfileState extends Equatable {
  const ProfileState();
  @override List<Object?> get props => [];
}
final class ProfileInitial extends ProfileState { const ProfileInitial(); }
final class ProfileLoading extends ProfileState { const ProfileLoading(); }
final class ProfileLoaded extends ProfileState {
  final ProfileEntity profile;
  final List<FeedbackEntity>? feedback;
  const ProfileLoaded({required this.profile, this.feedback});
  @override List<Object?> get props => [profile, feedback];
}
final class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);
  @override List<Object?> get props => [message];
}

// BLoC
@injectable
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  static const _tag = 'ProfileBloc';
  final GetProfileUseCase _getProfile;
  final GetOwnProfileUseCase _getOwnProfile;
  final GetFeedbackUseCase _getFeedback;

  ProfileBloc(this._getProfile, this._getOwnProfile, this._getFeedback)
      : super(const ProfileInitial()) {
    on<LoadProfile>(_onLoad);
    on<LoadFeedback>(_onLoadFeedback);
  }

  Future<void> _onLoad(LoadProfile event, Emitter<ProfileState> emit) async {
    AppLogger.d(_tag, 'Loading profile: ${event.userId ?? 'own'}');
    emit(const ProfileLoading());
    final result = event.userId != null
        ? await _getProfile(event.userId!)
        : await _getOwnProfile();
    result.fold(
      (f) { AppLogger.e(_tag, 'Load profile failed', f.message); emit(ProfileError(f.message)); },
      (profile) => emit(ProfileLoaded(profile: profile)),
    );
  }

  Future<void> _onLoadFeedback(LoadFeedback event, Emitter<ProfileState> emit) async {
    AppLogger.d(_tag, 'Loading feedback: ${event.userId}');
    final currentState = state;
    final result = await _getFeedback(event.userId);
    result.fold(
      (f) { AppLogger.e(_tag, 'Load feedback failed', f.message); emit(ProfileError(f.message)); },
      (feedback) {
        if (currentState is ProfileLoaded) {
          emit(ProfileLoaded(profile: currentState.profile, feedback: feedback));
        }
      },
    );
  }
}
