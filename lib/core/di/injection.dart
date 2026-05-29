import 'package:get_it/get_it.dart';

import '../../features/admin/data/datasources/admin_remote_data_source.dart';
import '../../features/admin/data/repositories/admin_repository_impl.dart';
import '../../features/admin/domain/repositories/admin_repository.dart';
import '../../features/admin/presentation/bloc/admin_bloc.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/messaging/data/datasources/messaging_data_source.dart';
import '../../features/messaging/data/repositories/messaging_repository_impl.dart';
import '../../features/messaging/domain/repositories/messaging_repository.dart';
import '../../features/messaging/presentation/bloc/messaging_bloc.dart';
import '../../features/notifications/data/datasources/notifications_data_source.dart';
import '../../features/notifications/data/repositories/notifications_repository_impl.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import '../../features/notifications/presentation/bloc/notifications_bloc.dart';
import '../../features/profile/data/datasources/profile_data_source.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/search/data/datasources/search_data_source.dart';
import '../../features/search/data/repositories/search_repository_impl.dart';
import '../../features/search/domain/repositories/search_repository.dart';
import '../../features/search/presentation/bloc/search_bloc.dart';
import '../../features/trading/data/datasources/trading_data_source.dart';
import '../../features/trading/data/repositories/offer_repository_impl.dart';
import '../../features/trading/data/repositories/trade_repository_impl.dart';
import '../../features/trading/domain/repositories/offer_repository.dart';
import '../../features/trading/domain/repositories/trade_repository.dart';
import '../../features/trading/presentation/bloc/offers_bloc.dart';
import '../../features/trading/presentation/bloc/trade_bloc.dart';
import '../../features/wallet/data/datasources/wallet_data_source.dart';
import '../../features/wallet/data/repositories/wallet_repository_impl.dart';
import '../../features/wallet/domain/repositories/wallet_repository.dart';
import '../../features/wallet/presentation/bloc/wallet_bloc.dart';
import '../network/api_client.dart';
import '../network/interceptors/auth_interceptor.dart';
import '../network/interceptors/error_interceptor.dart';
import '../security/biometric_service.dart';
import '../security/mnemonic_service.dart';
import '../security/pgp_service.dart';
import '../security/session_manager.dart';
import '../security/token_store.dart';
import '../security/totp_service.dart';

final GetIt sl = GetIt.instance;

Future<void> configureDependencies() async {
  if (sl.isRegistered<ApiClient>()) return;

  // --- Core ------------------------------------------------------------
  sl
    ..registerLazySingleton<TokenStore>(TokenStore.new)
    ..registerLazySingleton<MnemonicService>(MnemonicService.new)
    ..registerLazySingleton<TotpService>(TotpService.new)
    ..registerLazySingleton<PgpService>(PgpService.new)
    ..registerLazySingleton<BiometricService>(
      () => BiometricService(tokenStore: sl<TokenStore>()),
    )
    ..registerLazySingleton<SessionManager>(SessionManager.new)
    ..registerLazySingleton<AuthInterceptor>(
      () => AuthInterceptor(sl<TokenStore>()),
    )
    ..registerLazySingleton<ErrorInterceptor>(ErrorInterceptor.new)
    ..registerLazySingleton<ApiClient>(
      () => ApiClient(
        authInterceptor: sl<AuthInterceptor>(),
        errorInterceptor: sl<ErrorInterceptor>(),
      ),
    );

  // --- Data sources ----------------------------------------------------
  sl
    ..registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl(tokenStore: sl<TokenStore>()),
    )
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(client: sl<ApiClient>()),
    )
    ..registerLazySingleton<TradingDataSource>(
      () => InMemoryTradingDataSource(),
    )
    ..registerLazySingleton<WalletDataSource>(
      () => InMemoryWalletDataSource(),
    )
    ..registerLazySingleton<MessagingDataSource>(
      () => InMemoryMessagingDataSource(),
    )
    ..registerLazySingleton<ProfileDataSource>(
      () => InMemoryProfileDataSource(),
    )
    ..registerLazySingleton<SearchDataSource>(
      () => InMemorySearchDataSource(trading: sl<TradingDataSource>()),
    )
    ..registerLazySingleton<NotificationsDataSource>(
      () => InMemoryNotificationsDataSource(),
    )
    ..registerLazySingleton<AdminRemoteDataSource>(
      () => InMemoryAdminDataSource(),
    );

  // --- Repositories ----------------------------------------------------
  sl
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        remote: sl<AuthRemoteDataSource>(),
        local: sl<AuthLocalDataSource>(),
        mnemonic: sl<MnemonicService>(),
        totp: sl<TotpService>(),
        pgp: sl<PgpService>(),
      ),
    )
    ..registerLazySingleton<OfferRepository>(
      () => OfferRepositoryImpl(source: sl<TradingDataSource>()),
    )
    ..registerLazySingleton<TradeRepository>(
      () => TradeRepositoryImpl(source: sl<TradingDataSource>()),
    )
    ..registerLazySingleton<WalletRepository>(
      () => WalletRepositoryImpl(source: sl<WalletDataSource>()),
    )
    ..registerLazySingleton<MessagingRepository>(
      () => MessagingRepositoryImpl(source: sl<MessagingDataSource>()),
    )
    ..registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(source: sl<ProfileDataSource>()),
    )
    ..registerLazySingleton<SearchRepository>(
      () => SearchRepositoryImpl(source: sl<SearchDataSource>()),
    )
    ..registerLazySingleton<NotificationsRepository>(
      () => NotificationsRepositoryImpl(source: sl<NotificationsDataSource>()),
    )
    ..registerLazySingleton<AdminRepository>(
      () => AdminRepositoryImpl(source: sl<AdminRemoteDataSource>()),
    );

  // --- BLoCs (singletons for stable navigation/state) ------------------
  sl
    ..registerLazySingleton<AuthBloc>(
      () => AuthBloc(
        repository: sl<AuthRepository>(),
        sessionManager: sl<SessionManager>(),
        biometric: sl<BiometricService>(),
      ),
    )
    ..registerLazySingleton<WalletBloc>(
      () => WalletBloc(repository: sl<WalletRepository>()),
    )
    ..registerLazySingleton<NotificationsBloc>(
      () => NotificationsBloc(repository: sl<NotificationsRepository>()),
    )
    ..registerLazySingleton<ProfileBloc>(
      () => ProfileBloc(repository: sl<ProfileRepository>()),
    )
    ..registerFactory<OffersBloc>(
      () => OffersBloc(repository: sl<OfferRepository>()),
    )
    ..registerFactory<TradeBloc>(
      () => TradeBloc(repository: sl<TradeRepository>()),
    )
    ..registerFactory<MessagingBloc>(
      () => MessagingBloc(repository: sl<MessagingRepository>()),
    )
    ..registerFactory<SearchBloc>(
      () => SearchBloc(repository: sl<SearchRepository>()),
    )
    ..registerFactory<AdminBloc>(
      () => AdminBloc(repository: sl<AdminRepository>()),
    );
}
