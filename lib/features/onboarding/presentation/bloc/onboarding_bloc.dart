import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:capital_monero/core/logging/app_logger.dart';
import 'package:capital_monero/features/onboarding/domain/entities/onboarding_state_entity.dart';
import 'package:capital_monero/features/onboarding/domain/usecases/complete_onboarding_usecase.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

sealed class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

final class StartOnboarding extends OnboardingEvent {
  const StartOnboarding();
}

final class NextStep extends OnboardingEvent {
  const NextStep();
}

final class SkipBiometrics extends OnboardingEvent {
  const SkipBiometrics();
}

final class CompleteOnboarding extends OnboardingEvent {
  const CompleteOnboarding();
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

sealed class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object?> get props => [];
}

final class OnboardingInitial extends OnboardingState {
  const OnboardingInitial();
}

final class OnboardingInProgress extends OnboardingState {
  final OnboardingStep step;

  const OnboardingInProgress(this.step);

  @override
  List<Object?> get props => [step];
}

final class OnboardingComplete extends OnboardingState {
  const OnboardingComplete();
}

final class OnboardingError extends OnboardingState {
  final String message;

  const OnboardingError(this.message);

  @override
  List<Object?> get props => [message];
}

// ---------------------------------------------------------------------------
// BLoC
// ---------------------------------------------------------------------------

@injectable
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  static const _tag = 'OnboardingBloc';

  final CompleteOnboardingUseCase _completeOnboarding;

  OnboardingBloc(this._completeOnboarding) : super(const OnboardingInitial()) {
    on<StartOnboarding>(_onStart);
    on<NextStep>(_onNextStep);
    on<SkipBiometrics>(_onSkipBiometrics);
    on<CompleteOnboarding>(_onComplete);
  }

  void _onStart(StartOnboarding event, Emitter<OnboardingState> emit) {
    AppLogger.d(_tag, 'Starting onboarding');
    emit(const OnboardingInProgress(OnboardingStep.welcome));
  }

  void _onNextStep(NextStep event, Emitter<OnboardingState> emit) {
    final current = state;
    if (current is! OnboardingInProgress) return;

    final nextStep = switch (current.step) {
      OnboardingStep.welcome => OnboardingStep.seedBackup,
      OnboardingStep.seedBackup => OnboardingStep.biometricSetup,
      OnboardingStep.biometricSetup => OnboardingStep.pinSetup,
      OnboardingStep.pinSetup => OnboardingStep.complete,
      OnboardingStep.complete => OnboardingStep.complete,
    };

    AppLogger.d(_tag, 'Moving to step: $nextStep');

    if (nextStep == OnboardingStep.complete) {
      add(const CompleteOnboarding());
    } else {
      emit(OnboardingInProgress(nextStep));
    }
  }

  void _onSkipBiometrics(
    SkipBiometrics event,
    Emitter<OnboardingState> emit,
  ) {
    AppLogger.d(_tag, 'Skipping biometrics');
    emit(const OnboardingInProgress(OnboardingStep.pinSetup));
  }

  Future<void> _onComplete(
    CompleteOnboarding event,
    Emitter<OnboardingState> emit,
  ) async {
    AppLogger.d(_tag, 'Completing onboarding');
    final result = await _completeOnboarding();
    result.fold(
      (failure) {
        AppLogger.e(_tag, 'Failed to complete onboarding', failure.message);
        emit(OnboardingError(failure.message));
      },
      (_) => emit(const OnboardingComplete()),
    );
  }
}
