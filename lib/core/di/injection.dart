import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:capital_monero/core/config/environment.dart';
import 'package:capital_monero/core/storage/app_database.dart';

import 'injection.config.dart';

final GetIt getIt = GetIt.instance;

// ---------------------------------------------------------------------------
// External-dependency modules
// ---------------------------------------------------------------------------

@module
abstract class SharedPreferencesModule {
  /// Resolves and registers [SharedPreferences] asynchronously so that
  /// [PreferencesService] can receive it via constructor injection.
  @preResolve
  @singleton
  Future<SharedPreferences> get sharedPreferences =>
      SharedPreferences.getInstance();
}

@module
abstract class DatabaseModule {
  /// Creates the [AppDatabase] singleton.
  ///
  /// [AppDatabase.dbFileResolver] may be set before [configureInjection] is
  /// called to control the on-disk path (e.g. via `path_provider`).
  @singleton
  AppDatabase appDatabase() => AppDatabase();
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

/// Initialises the service locator.
///
/// [config] must be the correct [AppConfig] variant for the current build
/// (production / staging / fdroid).  Call this once from `main()` before
/// `runApp`.
@InjectableInit(
  initializerName: r'$initGetIt',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureInjection(AppConfig config) async {
  getIt.registerSingleton<AppConfig>(config);
  await getIt.$initGetIt();
}
