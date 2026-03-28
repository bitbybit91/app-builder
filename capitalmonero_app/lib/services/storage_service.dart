import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  StorageService._internal();
  static final StorageService instance = StorageService._internal();

  late FlutterSecureStorage _secureStorage;
  late SharedPreferences _prefs;

  static const _keyToken = 'auth_token';
  static const _keyUserJson = 'user_json';
  static const _keyTorMode = 'tor_mode';
  static const _keyBiometric = 'biometric_enabled';
  static const _keyPreferredCurrency = 'preferred_currency';

  Future<void> init() async {
    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    _prefs = await SharedPreferences.getInstance();
  }

  // --- Token (secure storage) ---

  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _keyToken, value: token);
  }

  Future<String?> getToken() async {
    return _secureStorage.read(key: _keyToken);
  }

  Future<void> clearToken() async {
    await _secureStorage.delete(key: _keyToken);
  }

  // --- User JSON (secure storage) ---

  Future<void> saveUserJson(String json) async {
    await _secureStorage.write(key: _keyUserJson, value: json);
  }

  Future<String?> getUserJson() async {
    return _secureStorage.read(key: _keyUserJson);
  }

  Future<void> clearUserJson() async {
    await _secureStorage.delete(key: _keyUserJson);
  }

  // --- Settings (shared preferences) ---

  bool getTorMode() => _prefs.getBool(_keyTorMode) ?? false;

  Future<void> setTorMode(bool val) async {
    await _prefs.setBool(_keyTorMode, val);
  }

  bool getBiometricEnabled() => _prefs.getBool(_keyBiometric) ?? false;

  Future<void> setBiometricEnabled(bool val) async {
    await _prefs.setBool(_keyBiometric, val);
  }

  String getPreferredCurrency() =>
      _prefs.getString(_keyPreferredCurrency) ?? 'USD';

  Future<void> setPreferredCurrency(String val) async {
    await _prefs.setString(_keyPreferredCurrency, val);
  }

  // --- Clear all ---

  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    await _prefs.clear();
  }
}
