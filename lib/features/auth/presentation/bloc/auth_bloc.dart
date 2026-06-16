import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final SecureStorageService secureStorage;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.secureStorage,
  }) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final token = await secureStorage.getAccessToken();
    if (token != null) {
      emit(const AuthAuthenticated(user: null));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await loginUseCase(LoginParams(
      username: event.username,
      password: event.password,
      otpCode: event.otpCode,
    ));
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (data) async {
        await secureStorage.saveAccessToken(data.tokens.accessToken);
        await secureStorage.saveRefreshToken(data.tokens.refreshToken);
        emit(AuthAuthenticated(user: data.user));
      },
    );
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await registerUseCase(RegisterParams(
      username: event.username,
      password: event.password,
    ));
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (data) async {
        await secureStorage.saveAccessToken(data.tokens.accessToken);
        await secureStorage.saveRefreshToken(data.tokens.refreshToken);
        if (data.mnemonic != null) {
          await secureStorage.saveMnemonic(data.mnemonic!);
        }
        emit(AuthRegistered(user: data.user, mnemonic: data.mnemonic));
      },
    );
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await logoutUseCase(const NoParams());
    await secureStorage.clearAll();
    emit(const AuthUnauthenticated());
  }
}
