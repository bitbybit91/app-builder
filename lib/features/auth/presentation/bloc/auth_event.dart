part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => const <Object?>[];
}

class AuthBootstrapRequested extends AuthEvent {
  const AuthBootstrapRequested();
}

class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({
    required this.username,
    required this.password,
    this.totpCode,
  });
  final String username;
  final String password;
  final String? totpCode;
  @override
  List<Object?> get props => <Object?>[username, password, totpCode];
}

class AuthRegisterRequested extends AuthEvent {
  const AuthRegisterRequested({
    required this.username,
    required this.password,
    this.email,
  });
  final String username;
  final String password;
  final String? email;
  @override
  List<Object?> get props => <Object?>[username, password, email];
}

class AuthRecoverRequested extends AuthEvent {
  const AuthRecoverRequested({
    required this.mnemonic,
    required this.newPassword,
  });
  final String mnemonic;
  final String newPassword;
  @override
  List<Object?> get props => <Object?>[mnemonic, newPassword];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthLockRequested extends AuthEvent {
  const AuthLockRequested();
}

class AuthUnlockRequested extends AuthEvent {
  const AuthUnlockRequested({this.pin});
  final String? pin;
  @override
  List<Object?> get props => <Object?>[pin];
}

class AuthMnemonicAcknowledged extends AuthEvent {
  const AuthMnemonicAcknowledged();
}

class _AuthSessionTimedOut extends AuthEvent {
  const _AuthSessionTimedOut();
}
