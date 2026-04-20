import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../network/api_client.dart';
import '../network/auth_interceptor.dart';
import '../notifications/notification_service.dart';
import '../storage/secure_storage_service.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/offers/data/datasources/offers_remote_datasource.dart';
import '../../features/offers/data/repositories/offers_repository_impl.dart';
import '../../features/offers/domain/repositories/offers_repository.dart';
import '../../features/offers/domain/usecases/get_offers_usecase.dart';
import '../../features/offers/domain/usecases/create_offer_usecase.dart';
import '../../features/offers/presentation/bloc/offers_bloc.dart';
import '../../features/trades/data/datasources/trades_remote_datasource.dart';
import '../../features/trades/data/repositories/trades_repository_impl.dart';
import '../../features/trades/domain/repositories/trades_repository.dart';
import '../../features/trades/domain/usecases/get_trades_usecase.dart';
import '../../features/trades/presentation/bloc/trades_bloc.dart';
import '../../features/wallet/data/datasources/wallet_remote_datasource.dart';
import '../../features/wallet/data/repositories/wallet_repository_impl.dart';
import '../../features/wallet/domain/repositories/wallet_repository.dart';
import '../../features/wallet/domain/usecases/get_wallet_balances_usecase.dart';
import '../../features/wallet/presentation/bloc/wallet_bloc.dart';
import '../../features/notifications/data/datasources/notifications_remote_datasource.dart';
import '../../features/notifications/data/repositories/notifications_repository_impl.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import '../../features/notifications/presentation/bloc/notifications_bloc.dart';
import '../../features/profile/data/datasources/profile_remote_datasource.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies({
  required NotificationService notificationService,
}) async {
  // Notifications – initialise the flavor-specific back-end and register it
  // so the rest of the app can depend on the abstract NotificationService.
  await notificationService.initialize();
  getIt.registerLazySingleton<NotificationService>(() => notificationService);

  // Core
  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );
  getIt.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(getIt<FlutterSecureStorage>()),
  );

  // Network
  getIt.registerLazySingleton<Dio>(() {
    final dio = Dio(BaseOptions(
      baseUrl: ApiClient.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    dio.interceptors.add(AuthInterceptor(getIt<SecureStorageService>()));
    return dio;
  });
  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(getIt<Dio>()),
  );

  // Auth
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt<AuthRemoteDataSource>()),
  );
  getIt.registerLazySingleton(() => LoginUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => RegisterUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => LogoutUseCase(getIt<AuthRepository>()));
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(
      loginUseCase: getIt<LoginUseCase>(),
      registerUseCase: getIt<RegisterUseCase>(),
      logoutUseCase: getIt<LogoutUseCase>(),
      secureStorage: getIt<SecureStorageService>(),
    ),
  );

  // Offers
  getIt.registerLazySingleton<OffersRemoteDataSource>(
    () => OffersRemoteDataSourceImpl(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<OffersRepository>(
    () => OffersRepositoryImpl(getIt<OffersRemoteDataSource>()),
  );
  getIt.registerLazySingleton(() => GetOffersUseCase(getIt<OffersRepository>()));
  getIt.registerLazySingleton(() => CreateOfferUseCase(getIt<OffersRepository>()));
  getIt.registerFactory<OffersBloc>(
    () => OffersBloc(
      getOffersUseCase: getIt<GetOffersUseCase>(),
      createOfferUseCase: getIt<CreateOfferUseCase>(),
    ),
  );

  // Trades
  getIt.registerLazySingleton<TradesRemoteDataSource>(
    () => TradesRemoteDataSourceImpl(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<TradesRepository>(
    () => TradesRepositoryImpl(getIt<TradesRemoteDataSource>()),
  );
  getIt.registerLazySingleton(() => GetTradesUseCase(getIt<TradesRepository>()));
  getIt.registerFactory<TradesBloc>(
    () => TradesBloc(getTradesUseCase: getIt<GetTradesUseCase>()),
  );

  // Wallet
  getIt.registerLazySingleton<WalletRemoteDataSource>(
    () => WalletRemoteDataSourceImpl(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<WalletRepository>(
    () => WalletRepositoryImpl(getIt<WalletRemoteDataSource>()),
  );
  getIt.registerLazySingleton(
    () => GetWalletBalancesUseCase(getIt<WalletRepository>()),
  );
  getIt.registerFactory<WalletBloc>(
    () => WalletBloc(
      getWalletBalancesUseCase: getIt<GetWalletBalancesUseCase>(),
    ),
  );

  // Notifications
  getIt.registerLazySingleton<NotificationsRemoteDataSource>(
    () => NotificationsRemoteDataSourceImpl(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<NotificationsRepository>(
    () => NotificationsRepositoryImpl(getIt<NotificationsRemoteDataSource>()),
  );
  getIt.registerFactory<NotificationsBloc>(
    () => NotificationsBloc(repository: getIt<NotificationsRepository>()),
  );

  // Profile
  getIt.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(getIt<ProfileRemoteDataSource>()),
  );
  getIt.registerFactory<ProfileBloc>(
    () => ProfileBloc(repository: getIt<ProfileRepository>()),
  );
}
