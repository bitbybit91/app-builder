import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/security/mnemonic_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final MnemonicService _mnemonicService = MnemonicService();

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<User> login(String username, String password) async {
    try {
      return await _remoteDataSource.login(username, password);
    } on ServerException catch (e) {
      throw AuthFailure(message: e.message);
    }
  }

  @override
  Future<User> register(String username, String password) async {
    try {
      return await _remoteDataSource.register(username, password);
    } on ServerException catch (e) {
      throw AuthFailure(message: e.message);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _remoteDataSource.logout();
    } on ServerException catch (e) {
      throw AuthFailure(message: e.message);
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    return await _remoteDataSource.getCurrentUser();
  }

  @override
  Future<bool> verifyTotp(String code) async {
    try {
      return await _remoteDataSource.verifyTotp(code);
    } on ServerException catch (e) {
      throw AuthFailure(message: e.message);
    }
  }

  @override
  Future<String> enableTotp() async {
    try {
      return await _remoteDataSource.enableTotp();
    } on ServerException catch (e) {
      throw AuthFailure(message: e.message);
    }
  }

  @override
  Future<String> generateMnemonic() async {
    return _mnemonicService.generateMnemonic();
  }

  @override
  Future<bool> recoverAccount(String mnemonic) async {
    if (!_mnemonicService.validateMnemonic(mnemonic)) {
      throw const AuthFailure(message: 'Invalid mnemonic phrase');
    }
    // In production, this would send the recovery key to the server
    return true;
  }

  @override
  Future<void> refreshToken() async {
    // Token refresh implementation
  }
}
