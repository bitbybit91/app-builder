import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/security/mnemonic_service.dart';
import '../../../../core/security/pgp_service.dart';
import '../../../../core/security/totp_service.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
    required MnemonicService mnemonic,
    required TotpService totp,
    required PgpService pgp,
  })  : _remote = remote,
        _local = local,
        _mnemonic = mnemonic,
        _totp = totp,
        _pgp = pgp;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;
  final MnemonicService _mnemonic;
  final TotpService _totp;
  final PgpService _pgp;

  @override
  Future<Either<Failure, AuthSession>> register({
    required String username,
    required String password,
    String? email,
  }) async {
    try {
      final String phrase = _mnemonic.generate();
      final String fp = _mnemonic.fingerprint(phrase);
      final AuthRemoteResult result = await _remote.register(<String, dynamic>{
        'username': username,
        'password': password,
        if (email != null) 'email': email,
        'mnemonic_fingerprint': fp,
      });
      await _persist(result, mnemonic: phrase);
      return Right<Failure, AuthSession>(AuthSession(
        user: result.user,
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        mnemonic: phrase,
      ));
    } on AuthException catch (e) {
      return Left<Failure, AuthSession>(AuthFailure(e.message, code: e.code));
    } on ServerException catch (e) {
      return Left<Failure, AuthSession>(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left<Failure, AuthSession>(NetworkFailure(e.message));
    } catch (e) {
      return Left<Failure, AuthSession>(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthSession>> login({
    required String username,
    required String password,
    String? totpCode,
  }) async {
    try {
      final AuthRemoteResult result = await _remote.login(<String, dynamic>{
        'username': username,
        'password': password,
        if (totpCode != null) 'totp': totpCode,
      });
      if (result.user.twoFactorEnabled && (totpCode == null || totpCode.isEmpty)) {
        return const Left<Failure, AuthSession>(
          AuthFailure('Two-factor code required', code: 'TOTP_REQUIRED'),
        );
      }
      await _persist(result);
      return Right<Failure, AuthSession>(AuthSession(
        user: result.user,
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      ));
    } on AuthException catch (e) {
      return Left<Failure, AuthSession>(AuthFailure(e.message, code: e.code));
    } on ServerException catch (e) {
      return Left<Failure, AuthSession>(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left<Failure, AuthSession>(NetworkFailure(e.message));
    } catch (e) {
      return Left<Failure, AuthSession>(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthSession>> recoverWithMnemonic({
    required String mnemonic,
    required String newPassword,
  }) async {
    if (!_mnemonic.validate(mnemonic)) {
      return const Left<Failure, AuthSession>(
        ValidationFailure('Invalid mnemonic phrase'),
      );
    }
    try {
      final String fp = _mnemonic.fingerprint(mnemonic);
      final AuthRemoteResult result = await _remote.recover(<String, dynamic>{
        'mnemonic_fingerprint': fp,
        'new_password': newPassword,
      });
      await _persist(result, mnemonic: mnemonic);
      return Right<Failure, AuthSession>(AuthSession(
        user: result.user,
        accessToken: result.accessToken,
        mnemonic: mnemonic,
      ));
    } on AuthException catch (e) {
      return Left<Failure, AuthSession>(AuthFailure(e.message, code: e.code));
    } on ServerException catch (e) {
      return Left<Failure, AuthSession>(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left<Failure, AuthSession>(NetworkFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    await _remote.logout();
    await _local.clearTokens();
    await _local.clearUser();
    return const Right<Failure, Unit>(unit);
  }

  @override
  Future<Either<Failure, User>> currentUser() async {
    final UserModel? cached = await _local.cachedUser();
    if (cached != null) return Right<Failure, User>(cached);
    try {
      final UserModel fresh = await _remote.me();
      await _local.cacheUser(fresh);
      return Right<Failure, User>(fresh);
    } on AuthException catch (e) {
      return Left<Failure, User>(AuthFailure(e.message, code: e.code));
    } catch (e) {
      return Left<Failure, User>(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthSession?>> bootstrap() async {
    final String? token = await _local.readAccessToken();
    final UserModel? cached = await _local.cachedUser();
    if (token == null || cached == null) {
      return const Right<Failure, AuthSession?>(null);
    }
    return Right<Failure, AuthSession?>(
      AuthSession(user: cached, accessToken: token),
    );
  }

  @override
  Future<Either<Failure, String>> beginTwoFactorSetup() async {
    final String secret = _totp.generateSecret();
    try {
      await _remote.beginTwoFactorSetup();
    } catch (_) {
      // Offline: generate locally and let the user enroll.
    }
    return Right<Failure, String>(secret);
  }

  @override
  Future<Either<Failure, Unit>> confirmTwoFactor({
    required String secret,
    required String code,
  }) async {
    if (!_totp.verify(code, secret)) {
      return const Left<Failure, Unit>(
        AuthFailure('Invalid 2FA code', code: 'TOTP_INVALID'),
      );
    }
    try {
      await _remote.confirmTwoFactor(secret, code);
    } catch (_) {}
    return const Right<Failure, Unit>(unit);
  }

  @override
  Future<Either<Failure, Unit>> attachPgpKey(String publicKey) async {
    if (!_pgp.fingerprint(publicKey).isNotEmpty) {
      return const Left<Failure, Unit>(CryptoFailure('Invalid PGP key'));
    }
    try {
      await _remote.attachPgpKey(publicKey);
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left<Failure, Unit>(UnexpectedFailure(e.toString()));
    }
  }

  Future<void> _persist(AuthRemoteResult result, {String? mnemonic}) async {
    await _local.saveTokens(
      access: result.accessToken,
      refresh: result.refreshToken,
    );
    await _local.cacheUser(result.user);
    if (mnemonic != null) {
      await _local.saveMnemonic(mnemonic);
    }
  }
}
