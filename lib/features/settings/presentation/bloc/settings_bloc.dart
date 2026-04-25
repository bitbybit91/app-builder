import 'dart:ui';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:capital_monero/core/logging/app_logger.dart';
import 'package:capital_monero/features/settings/domain/entities/settings_entity.dart';
import 'package:capital_monero/features/settings/domain/usecases/get_settings_usecase.dart';
import 'package:capital_monero/features/settings/domain/usecases/update_settings_usecase.dart';

// Events
sealed class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override List<Object?> get props => [];
}
final class LoadSettings extends SettingsEvent { const LoadSettings(); }
final class UpdateTheme extends SettingsEvent {
  final ThemeMode themeMode;
  const UpdateTheme(this.themeMode);
  @override List<Object?> get props => [themeMode];
}
final class UpdateLocale extends SettingsEvent {
  final Locale locale;
  const UpdateLocale(this.locale);
  @override List<Object?> get props => [locale];
}
final class ToggleTor extends SettingsEvent { const ToggleTor(); }
final class UpdateNodeUrl extends SettingsEvent {
  final String? nodeUrl;
  const UpdateNodeUrl(this.nodeUrl);
  @override List<Object?> get props => [nodeUrl];
}
final class ToggleBiometric extends SettingsEvent { const ToggleBiometric(); }

// States
sealed class SettingsState extends Equatable {
  const SettingsState();
  @override List<Object?> get props => [];
}
final class SettingsInitial extends SettingsState { const SettingsInitial(); }
final class SettingsLoaded extends SettingsState {
  final AppSettings settings;
  const SettingsLoaded(this.settings);
  @override List<Object?> get props => [settings];
}
final class SettingsError extends SettingsState {
  final String message;
  const SettingsError(this.message);
  @override List<Object?> get props => [message];
}

// BLoC
@injectable
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  static const _tag = 'SettingsBloc';
  final GetSettingsUseCase _getSettings;
  final UpdateSettingsUseCase _updateSettings;

  SettingsBloc(this._getSettings, this._updateSettings) : super(const SettingsInitial()) {
    on<LoadSettings>(_onLoad);
    on<UpdateTheme>(_onUpdateTheme);
    on<UpdateLocale>(_onUpdateLocale);
    on<ToggleTor>(_onToggleTor);
    on<UpdateNodeUrl>(_onUpdateNodeUrl);
    on<ToggleBiometric>(_onToggleBiometric);
  }

  void _onLoad(LoadSettings event, Emitter<SettingsState> emit) {
    AppLogger.d(_tag, 'Loading settings');
    try {
      emit(SettingsLoaded(_getSettings()));
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> _persist(AppSettings settings, Emitter<SettingsState> emit) async {
    try {
      await _updateSettings(settings);
      emit(SettingsLoaded(settings));
    } catch (e) {
      AppLogger.e(_tag, 'Failed to save settings', e);
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> _onUpdateTheme(UpdateTheme event, Emitter<SettingsState> emit) async {
    final current = _currentSettings;
    await _persist(current.copyWith(themeMode: event.themeMode), emit);
  }

  Future<void> _onUpdateLocale(UpdateLocale event, Emitter<SettingsState> emit) async {
    await _persist(_currentSettings.copyWith(locale: event.locale), emit);
  }

  Future<void> _onToggleTor(ToggleTor event, Emitter<SettingsState> emit) async {
    final current = _currentSettings;
    await _persist(current.copyWith(torEnabled: !current.torEnabled), emit);
  }

  Future<void> _onUpdateNodeUrl(UpdateNodeUrl event, Emitter<SettingsState> emit) async {
    await _persist(_currentSettings.copyWith(nodeUrl: event.nodeUrl), emit);
  }

  Future<void> _onToggleBiometric(ToggleBiometric event, Emitter<SettingsState> emit) async {
    final current = _currentSettings;
    await _persist(current.copyWith(biometricEnabled: !current.biometricEnabled), emit);
  }

  AppSettings get _currentSettings => state is SettingsLoaded
      ? (state as SettingsLoaded).settings
      : _getSettings();
}
