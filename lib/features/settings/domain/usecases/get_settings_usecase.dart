import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:capital_monero/core/storage/preferences_service.dart';
import 'package:capital_monero/features/settings/domain/entities/settings_entity.dart';

@injectable
class GetSettingsUseCase {
  final PreferencesService _preferences;
  const GetSettingsUseCase(this._preferences);

  AppSettings call() {
    final themeModeIndex = _preferences.getInt(PreferencesService.kThemeModeKey) ?? 0;
    final localeCode = _preferences.getString(PreferencesService.kLocaleKey) ?? 'en';
    final torEnabled = _preferences.getBool(PreferencesService.kTorEnabledKey) ?? false;
    final nodeUrl = _preferences.getString(PreferencesService.kNodeUrlKey);
    final biometricEnabled = _preferences.getBool(PreferencesService.kBiometricEnabledKey) ?? false;

    return AppSettings(
      themeMode: ThemeMode.values[themeModeIndex.clamp(0, ThemeMode.values.length - 1)],
      locale: Locale(localeCode),
      torEnabled: torEnabled,
      nodeUrl: nodeUrl,
      biometricEnabled: biometricEnabled,
    );
  }
}
