// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import 'package:capital_monero/core/config/environment.dart' as _i200;
import 'package:capital_monero/core/crypto/key_derivation.dart' as _i847;
import 'package:capital_monero/core/crypto/mnemonic_service.dart' as _i762;
import 'package:capital_monero/core/network/api_client.dart' as _i305;
import 'package:capital_monero/core/storage/app_database.dart' as _i111;
import 'package:capital_monero/core/storage/preferences_service.dart' as _i984;
import 'package:capital_monero/core/storage/secure_storage_service.dart'
    as _i721;

import 'injection.dart' as _i693;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> $initGetIt({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final sharedPreferencesModule = _$SharedPreferencesModule();
    final databaseModule = _$DatabaseModule();

    await gh.singletonAsync<_i460.SharedPreferences>(
      () => sharedPreferencesModule.sharedPreferences,
      preResolve: true,
    );
    gh.singleton<_i111.AppDatabase>(
      () => databaseModule.appDatabase(),
    );
    gh.singleton<_i721.SecureStorageService>(
      () => _i721.SecureStorageService(),
    );
    gh.singleton<_i984.PreferencesService>(
      () => _i984.PreferencesService(gh<_i460.SharedPreferences>()),
    );
    gh.singleton<_i847.KeyDerivationService>(
      () => _i847.KeyDerivationService(),
    );
    gh.singleton<_i762.MnemonicService>(
      () => _i762.MnemonicService(),
    );
    gh.singleton<_i305.DioApiClient>(
      () => _i305.DioApiClient(
        gh<_i200.AppConfig>(),
        gh<_i721.SecureStorageService>(),
      ),
    );
    return this;
  }
}

class _$SharedPreferencesModule extends _i693.SharedPreferencesModule {}

class _$DatabaseModule extends _i693.DatabaseModule {}
