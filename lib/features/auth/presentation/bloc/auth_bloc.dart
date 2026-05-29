import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/security/biometric_service.dart';
import '../../../../core/security/session_manager.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required AuthRepository repository,
    required SessionManager sessionManager,
    required BiometricService biometric,
  })  : _repository = repository,
        _sessionManager = sessionManager,
        _biometric = biometric,
        super(const AuthInitial()) {
    on<AuthBootstrapRequested>(_onBootstrap);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthRecoverRequested>(_onRecover);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthLockRequested>(_onLock);
    on<AuthUnlockRequested>(_onUnlock);
    on<AuthMnemonicAcknowledged>(_onMnemonicAcknowledged);
    on<_AuthSessionTimedOut>((_AuthSessionTimedOut event, Emitter<AuthState> emit) {
      if (state is AuthAuthenticated) {
        emit(AuthLocked(session: (state as AuthAuthenticated).session));
      }
    });

    _sessionListener = _onSessionChanged;
    _sessionManager.addListener(_sessionListener);

    add(const AuthBootstrapRequested());
  }

  final AuthRepository _repository;
  final SessionManager _sessionManager;
  final BiometricService _biometric;
  late final VoidCallback _sessionListener;

  void _onSessionChanged() {
    if (_sessionManager.isLocked) {
      add(const _AuthSessionTimedOut());
    }
  }

  Future<void> _onBootstrap(
    AuthBootstrapRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final Either<Failure, AuthSession?> result = await _repository.bootstrap();
    result.fold(
      (Failure f) => emit(const AuthUnauthenticated()),
      (AuthSession? session) {
        if (session == null) {
          emit(const AuthUnauthenticated());
        } else {
          _sessionManager.start();
          emit(AuthAuthenticated(session: session));
        }
      },
    );
  }

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final Either<Failure, AuthSession> result = await _repository.login(
      username: event.username,
      password: event.password,
      totpCode: event.totpCode,
    );
    result.fold(
      (Failure f) => emit(AuthFailureState(f)),
      (AuthSession session) {
        _sessionManager.start();
        emit(AuthAuthenticated(session: session));
      },
    );
  }

  Future<void> _onRegister(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final Either<Failure, AuthSession> result = await _repository.register(
      username: event.username,
      password: event.password,
      email: event.email,
    );
    result.fold(
      (Failure f) => emit(AuthFailureState(f)),
      (AuthSession session) {
        _sessionManager.start();
        emit(AuthAuthenticated(session: session, freshMnemonic: session.mnemonic));
      },
    );
  }

  Future<void> _onRecover(
    AuthRecoverRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final Either<Failure, AuthSession> result =
        await _repository.recoverWithMnemonic(
      mnemonic: event.mnemonic,
      newPassword: event.newPassword,
    );
    result.fold(
      (Failure f) => emit(AuthFailureState(f)),
      (AuthSession session) {
        _sessionManager.start();
        emit(AuthAuthenticated(session: session));
      },
    );
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repository.logout();
    emit(const AuthUnauthenticated());
  }

  void _onLock(AuthLockRequested event, Emitter<AuthState> emit) {
    if (state is AuthAuthenticated) {
      emit(AuthLocked(session: (state as AuthAuthenticated).session));
    }
  }

  Future<void> _onUnlock(
    AuthUnlockRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! AuthLocked) return;
    final bool ok = event.pin != null
        ? await _biometric.verifyPin(event.pin!)
        : await _biometric.authenticate();
    if (!ok) return;
    final AuthSession session = (state as AuthLocked).session;
    _sessionManager.unlock();
    emit(AuthAuthenticated(session: session));
  }

  void _onMnemonicAcknowledged(
    AuthMnemonicAcknowledged event,
    Emitter<AuthState> emit,
  ) {
    if (state is AuthAuthenticated) {
      emit((state as AuthAuthenticated).copyWith(freshMnemonic: null));
    }
  }

  @override
  Future<void> close() {
    _sessionManager.removeListener(_sessionListener);
    return super.close();
  }
}
