part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoginRequested extends AuthEvent {
  final String username;
  final String password;
  final String? otpCode;

  const AuthLoginRequested({
    required this.username,
    required this.password,
    this.otpCode,
  });

  @override
  List<Object?> get props => [username, password, otpCode];
}

class AuthRegisterRequested extends AuthEvent {
  final String username;
  final String password;

  const AuthRegisterRequested({
    required this.username,
    required this.password,
  });

  @override
  List<Object?> get props => [username, password];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
