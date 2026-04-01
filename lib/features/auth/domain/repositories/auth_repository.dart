import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login(String username, String password);
  Future<User> register(String username, String password);
  Future<void> logout();
  Future<User?> getCurrentUser();
  Future<bool> verifyTotp(String code);
  Future<String> enableTotp();
  Future<String> generateMnemonic();
  Future<bool> recoverAccount(String mnemonic);
  Future<void> refreshToken();
}
