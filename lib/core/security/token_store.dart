import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps [FlutterSecureStorage] for auth tokens. Kept in its own file so the
/// auth interceptor does not need to know about secure-storage details and
/// can be mocked in tests.
class TokenStore {
  TokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  static const String _accessKey = 'capitalmonero.access_token';
  static const String _refreshKey = 'capitalmonero.refresh_token';
  static const String _mnemonicKey = 'capitalmonero.mnemonic';
  static const String _pinKey = 'capitalmonero.pin_hash';

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() => _storage.read(key: _accessKey);
  Future<String?> readRefreshToken() => _storage.read(key: _refreshKey);

  Future<void> writeTokens({
    required String access,
    String? refresh,
  }) async {
    await _storage.write(key: _accessKey, value: access);
    if (refresh != null) {
      await _storage.write(key: _refreshKey, value: refresh);
    }
  }

  Future<void> writeMnemonic(String mnemonic) =>
      _storage.write(key: _mnemonicKey, value: mnemonic);
  Future<String?> readMnemonic() => _storage.read(key: _mnemonicKey);

  Future<void> writePinHash(String hash) =>
      _storage.write(key: _pinKey, value: hash);
  Future<String?> readPinHash() => _storage.read(key: _pinKey);

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }

  Future<void> wipeEverything() => _storage.deleteAll();
}
