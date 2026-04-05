part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final User? user;

  const AuthAuthenticated({this.user});

  @override
  List<Object?> get props => [user];
}

class AuthRegistered extends AuthState {
  final User user;
  final String? mnemonic;

  const AuthRegistered({required this.user, this.mnemonic});

  @override
  List<Object?> get props => [user, mnemonic];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}
