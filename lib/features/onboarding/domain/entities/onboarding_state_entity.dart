import 'package:equatable/equatable.dart';

enum OnboardingStep { welcome, seedBackup, biometricSetup, pinSetup, complete }

class OnboardingStateEntity extends Equatable {
  final OnboardingStep currentStep;
  final bool isComplete;
  final bool hasBiometrics;

  const OnboardingStateEntity({
    required this.currentStep,
    required this.isComplete,
    required this.hasBiometrics,
  });

  OnboardingStateEntity copyWith({
    OnboardingStep? currentStep,
    bool? isComplete,
    bool? hasBiometrics,
  }) =>
      OnboardingStateEntity(
        currentStep: currentStep ?? this.currentStep,
        isComplete: isComplete ?? this.isComplete,
        hasBiometrics: hasBiometrics ?? this.hasBiometrics,
      );

  @override
  List<Object?> get props => [currentStep, isComplete, hasBiometrics];

  @override
  bool get stringify => true;
}
