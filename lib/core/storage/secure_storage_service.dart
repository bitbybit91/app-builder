import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService(this._storage);

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _pinKey = 'user_pin';
  static const _mnemonicKey = 'recovery_mnemonic';
  static const _biometricEnabledKey = 'biometric_enabled';

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  Future<String?> getAccessToken() =>
      _storage.read(key: _accessTokenKey);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  Future<String?> getRefreshToken() =>
      _storage.read(key: _refreshTokenKey);

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<void> savePin(String pin) =>
      _storage.write(key: _pinKey, value: pin);

  Future<String?> getPin() =>
      _storage.read(key: _pinKey);

  Future<void> saveMnemonic(String mnemonic) =>
      _storage.write(key: _mnemonicKey, value: mnemonic);

  Future<String?> getMnemonic() =>
      _storage.read(key: _mnemonicKey);

  Future<void> setBiometricEnabled(bool enabled) =>
      _storage.write(key: _biometricEnabledKey, value: enabled.toString());

  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  Future<void> clearAll() => _storage.deleteAll();
}
