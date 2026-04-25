import 'dart:ui';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class AppSettings extends Equatable {
  final ThemeMode themeMode;
  final Locale locale;
  final bool torEnabled;
  final String? nodeUrl;
  final bool biometricEnabled;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('en'),
    this.torEnabled = false,
    this.nodeUrl,
    this.biometricEnabled = false,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool? torEnabled,
    String? nodeUrl,
    bool? biometricEnabled,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        locale: locale ?? this.locale,
        torEnabled: torEnabled ?? this.torEnabled,
        nodeUrl: nodeUrl ?? this.nodeUrl,
        biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      );

  @override
  List<Object?> get props => [themeMode, locale, torEnabled, nodeUrl, biometricEnabled];
  @override bool get stringify => true;
}
