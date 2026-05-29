import 'package:equatable/equatable.dart';

import 'user.dart';

class AuthSession extends Equatable {
  const AuthSession({
    required this.user,
    required this.accessToken,
    this.refreshToken,
    this.mnemonic,
  });

  final User user;
  final String accessToken;
  final String? refreshToken;
  final String? mnemonic;

  @override
  List<Object?> get props => <Object?>[user, accessToken, refreshToken, mnemonic];
}
