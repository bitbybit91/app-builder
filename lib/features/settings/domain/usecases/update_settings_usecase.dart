import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:capital_monero/core/storage/preferences_service.dart';
import 'package:capital_monero/features/settings/domain/entities/settings_entity.dart';

@injectable
class UpdateSettingsUseCase {
  final PreferencesService _preferences;
  const UpdateSettingsUseCase(this._preferences);

  Future<void> call(AppSettings settings) async {
    await Future.wait([
      _preferences.setInt(PreferencesService.kThemeModeKey, value: settings.themeMode.index),
      _preferences.setString(PreferencesService.kLocaleKey, value: settings.locale.languageCode),
      _preferences.setBool(PreferencesService.kTorEnabledKey, value: settings.torEnabled),
      _preferences.setBool(PreferencesService.kBiometricEnabledKey, value: settings.biometricEnabled),
    ]);
    if (settings.nodeUrl != null) {
      await _preferences.setString(PreferencesService.kNodeUrlKey, value: settings.nodeUrl!);
    } else {
      await _preferences.remove(PreferencesService.kNodeUrlKey);
    }
  }
}
