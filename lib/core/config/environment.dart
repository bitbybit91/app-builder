import 'package:equatable/equatable.dart';

const bool kFdroidBuild = bool.fromEnvironment('FDROID_BUILD');

enum AppFlavor { production, staging, fdroid }

class AppConfig extends Equatable {
  final AppFlavor flavor;
  final String apiBaseUrl;
  final bool isDev;
  final bool torEnabled;

  const AppConfig({
    required this.flavor,
    required this.apiBaseUrl,
    required this.isDev,
    this.torEnabled = false,
  });

  factory AppConfig.production() => const AppConfig(
        flavor: AppFlavor.production,
        apiBaseUrl: 'https://api.capitalmonero.com/v1',
        isDev: false,
      );

  factory AppConfig.staging() => const AppConfig(
        flavor: AppFlavor.staging,
        apiBaseUrl: 'https://staging-api.capitalmonero.com/v1',
        isDev: true,
      );

  factory AppConfig.fdroid() => const AppConfig(
        flavor: AppFlavor.fdroid,
        apiBaseUrl: 'https://api.capitalmonero.com/v1',
        isDev: false,
      );

  AppConfig copyWith({
    AppFlavor? flavor,
    String? apiBaseUrl,
    bool? isDev,
    bool? torEnabled,
  }) =>
      AppConfig(
        flavor: flavor ?? this.flavor,
        apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
        isDev: isDev ?? this.isDev,
        torEnabled: torEnabled ?? this.torEnabled,
      );

  @override
  List<Object?> get props => [flavor, apiBaseUrl, isDev, torEnabled];

  @override
  bool get stringify => true;
}
