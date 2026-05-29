import 'package:bloc_test/bloc_test.dart';
import 'package:capitalmonero/core/errors/failures.dart';
import 'package:capitalmonero/core/security/biometric_service.dart';
import 'package:capitalmonero/core/security/session_manager.dart';
import 'package:capitalmonero/features/auth/domain/entities/auth_session.dart';
import 'package:capitalmonero/features/auth/domain/entities/user.dart';
import 'package:capitalmonero/features/auth/domain/repositories/auth_repository.dart';
import 'package:capitalmonero/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements AuthRepository {}
class _MockBiometric extends Mock implements BiometricService {}

void main() {
  late _MockRepo repo;
  late _MockBiometric biometric;
  late SessionManager session;

  final User testUser = User(
    id: 'u1',
    username: 'alice',
    role: UserRole.user,
    createdAt: DateTime(2024),
  );
  final AuthSession testSession =
      AuthSession(user: testUser, accessToken: 'tok');

  setUp(() {
    repo = _MockRepo();
    biometric = _MockBiometric();
    session = SessionManager(timeout: const Duration(minutes: 5));
    when(() => repo.bootstrap())
        .thenAnswer((_) async => const Right<Failure, AuthSession?>(null));
  });

  blocTest<AuthBloc, AuthState>(
    'emits Unauthenticated after bootstrap when no session is cached',
    build: () => AuthBloc(
      repository: repo,
      sessionManager: session,
      biometric: biometric,
    ),
    expect: () => <Object?>[
      isA<AuthLoading>(),
      isA<AuthUnauthenticated>(),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'successful login emits Authenticated',
    build: () {
      when(() => repo.login(
            username: any(named: 'username'),
            password: any(named: 'password'),
            totpCode: any(named: 'totpCode'),
          )).thenAnswer(
        (_) async => Right<Failure, AuthSession>(testSession),
      );
      return AuthBloc(
        repository: repo,
        sessionManager: session,
        biometric: biometric,
      );
    },
    act: (AuthBloc bloc) async {
      // Wait for bootstrap to settle first.
      await Future<void>.delayed(Duration.zero);
      bloc.add(const AuthLoginRequested(username: 'alice', password: 'pw'));
    },
    skip: 2,
    expect: () => <Object?>[
      isA<AuthLoading>(),
      isA<AuthAuthenticated>(),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'login failure emits AuthFailureState',
    build: () {
      when(() => repo.login(
            username: any(named: 'username'),
            password: any(named: 'password'),
            totpCode: any(named: 'totpCode'),
          )).thenAnswer(
        (_) async => const Left<Failure, AuthSession>(
          AuthFailure('Invalid credentials', code: 'INVALID_CREDENTIALS'),
        ),
      );
      return AuthBloc(
        repository: repo,
        sessionManager: session,
        biometric: biometric,
      );
    },
    act: (AuthBloc bloc) async {
      await Future<void>.delayed(Duration.zero);
      bloc.add(const AuthLoginRequested(username: 'alice', password: 'bad'));
    },
    skip: 2,
    expect: () => <Object?>[
      isA<AuthLoading>(),
      isA<AuthFailureState>(),
    ],
  );
}
