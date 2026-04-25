import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@singleton
class PreferencesService {
  static const String kThemeModeKey = 'theme_mode';
  static const String kLocaleKey = 'locale';
  static const String kTorEnabledKey = 'tor_enabled';
  static const String kNodeUrlKey = 'node_url';
  static const String kOnboardingCompleteKey = 'onboarding_complete';
  static const String kBiometricEnabledKey = 'biometric_enabled';

  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  bool? getBool(String key) => _prefs.getBool(key);

  Future<bool> setBool(String key, {required bool value}) =>
      _prefs.setBool(key, value);

  String? getString(String key) => _prefs.getString(key);

  Future<bool> setString(String key, {required String value}) =>
      _prefs.setString(key, value);

  int? getInt(String key) => _prefs.getInt(key);

  Future<bool> setInt(String key, {required int value}) =>
      _prefs.setInt(key, value);

  Future<bool> remove(String key) => _prefs.remove(key);
}
