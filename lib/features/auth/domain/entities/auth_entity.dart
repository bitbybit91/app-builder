import 'package:equatable/equatable.dart';

enum AuthStatus { unauthenticated, authenticated, locked }

class AuthEntity extends Equatable {
  final AuthStatus status;
  final String? userId;
  final DateTime? sessionExpiresAt;

  const AuthEntity({
    required this.status,
    this.userId,
    this.sessionExpiresAt,
  });

  AuthEntity copyWith({
    AuthStatus? status,
    String? userId,
    DateTime? sessionExpiresAt,
  }) =>
      AuthEntity(
        status: status ?? this.status,
        userId: userId ?? this.userId,
        sessionExpiresAt: sessionExpiresAt ?? this.sessionExpiresAt,
      );

  @override
  List<Object?> get props => [status, userId, sessionExpiresAt];

  @override
  bool get stringify => true;
}
