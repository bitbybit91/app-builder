import 'dart:convert';

import '../../../../core/security/token_store.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> cachedUser();
  Future<void> clearUser();
  Future<void> saveTokens({required String access, String? refresh});
  Future<String?> readAccessToken();
  Future<void> clearTokens();
  Future<void> saveMnemonic(String mnemonic);
  Future<String?> readMnemonic();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl({required TokenStore tokenStore})
      : _tokenStore = tokenStore;

  final TokenStore _tokenStore;

  static const String _userKey = 'capitalmonero.user';
  final Map<String, String> _kvFallback = <String, String>{};

  @override
  Future<void> cacheUser(UserModel user) async {
    _kvFallback[_userKey] = jsonEncode(user.toJson());
  }

  @override
  Future<UserModel?> cachedUser() async {
    final String? raw = _kvFallback[_userKey];
    if (raw == null) return null;
    return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> clearUser() async {
    _kvFallback.remove(_userKey);
  }

  @override
  Future<void> saveTokens({required String access, String? refresh}) =>
      _tokenStore.writeTokens(access: access, refresh: refresh);

  @override
  Future<String?> readAccessToken() => _tokenStore.readAccessToken();

  @override
  Future<void> clearTokens() => _tokenStore.clear();

  @override
  Future<void> saveMnemonic(String mnemonic) =>
      _tokenStore.writeMnemonic(mnemonic);

  @override
  Future<String?> readMnemonic() => _tokenStore.readMnemonic();
}
