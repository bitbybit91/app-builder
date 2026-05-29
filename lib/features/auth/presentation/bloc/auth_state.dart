part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => const <Object?>[];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.session, this.freshMnemonic});
  final AuthSession session;
  final String? freshMnemonic;

  AuthAuthenticated copyWith({AuthSession? session, String? freshMnemonic}) {
    return AuthAuthenticated(
      session: session ?? this.session,
      freshMnemonic: freshMnemonic,
    );
  }

  @override
  List<Object?> get props => <Object?>[session, freshMnemonic];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({this.message});
  final String? message;
  @override
  List<Object?> get props => <Object?>[message];
}

class AuthLocked extends AuthState {
  const AuthLocked({required this.session});
  final AuthSession session;
  @override
  List<Object?> get props => <Object?>[session];
}

class AuthFailureState extends AuthState {
  const AuthFailureState(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => <Object?>[failure];
}
