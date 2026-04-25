import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:capital_monero/core/logging/app_logger.dart';
import 'package:capital_monero/features/auth/domain/usecases/authenticate_pin_usecase.dart';
import 'package:capital_monero/features/auth/domain/usecases/biometric_auth_usecase.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

final class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();
}

final class AuthenticateWithPin extends AuthEvent {
  final String pin;

  const AuthenticateWithPin(this.pin);

  @override
  List<Object?> get props => [pin];
}

final class AuthenticateWithBiometric extends AuthEvent {
  const AuthenticateWithBiometric();
}

final class Logout extends AuthEvent {
  const Logout();
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated();
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

final class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

// ---------------------------------------------------------------------------
// BLoC
// ---------------------------------------------------------------------------

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  static const _tag = 'AuthBloc';

  final AuthenticatePinUseCase _authenticatePin;
  final BiometricAuthUseCase _biometricAuth;

  AuthBloc(this._authenticatePin, this._biometricAuth)
      : super(const AuthInitial()) {
    on<CheckAuthStatus>(_onCheckStatus);
    on<AuthenticateWithPin>(_onAuthWithPin);
    on<AuthenticateWithBiometric>(_onAuthWithBiometric);
    on<Logout>(_onLogout);
  }

  void _onCheckStatus(CheckAuthStatus event, Emitter<AuthState> emit) {
    AppLogger.d(_tag, 'Checking auth status');
    emit(const AuthUnauthenticated());
  }

  Future<void> _onAuthWithPin(
    AuthenticateWithPin event,
    Emitter<AuthState> emit,
  ) async {
    AppLogger.d(_tag, 'Authenticating with PIN');
    emit(const AuthLoading());

    final result = await _authenticatePin(event.pin);
    result.fold(
      (failure) {
        AppLogger.e(_tag, 'PIN auth failed', failure.message);
        emit(AuthError(failure.message));
      },
      (isValid) {
        if (isValid) {
          emit(const AuthAuthenticated());
        } else {
          emit(const AuthError('Incorrect PIN'));
        }
      },
    );
  }

  Future<void> _onAuthWithBiometric(
    AuthenticateWithBiometric event,
    Emitter<AuthState> emit,
  ) async {
    AppLogger.d(_tag, 'Authenticating with biometrics');
    emit(const AuthLoading());

    final result = await _biometricAuth();
    result.fold(
      (failure) {
        AppLogger.e(_tag, 'Biometric auth failed', failure.message);
        emit(AuthError(failure.message));
      },
      (authenticated) {
        if (authenticated) {
          emit(const AuthAuthenticated());
        } else {
          emit(const AuthUnauthenticated());
        }
      },
    );
  }

  void _onLogout(Logout event, Emitter<AuthState> emit) {
    AppLogger.d(_tag, 'Logging out');
    emit(const AuthUnauthenticated());
  }
}
