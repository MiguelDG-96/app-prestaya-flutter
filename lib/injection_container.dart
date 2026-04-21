import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsign;
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:app_prestaya_flutter/core/network/dio_client.dart';
import 'package:app_prestaya_flutter/features/stats/data/datasources/stats_remote_datasource.dart' as stats_ds;
import 'package:app_prestaya_flutter/features/stats/data/repositories/stats_repository_impl.dart' as stats_repo;
import 'package:app_prestaya_flutter/features/stats/presentation/bloc/stats_bloc.dart' as stats_bloc;
import 'package:app_prestaya_flutter/core/services/export_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Auth
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/upload_photo_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

// Clients
import 'features/clients/domain/repositories/client_repository.dart';
import 'features/clients/data/repositories/client_repository_impl.dart';
import 'features/clients/data/datasources/client_remote_datasource.dart';
import 'features/clients/domain/usecases/get_clients_usecase.dart';
import 'features/clients/domain/usecases/add_client_usecase.dart';
import 'features/clients/domain/usecases/client_actions_usecases.dart';
import 'features/clients/presentation/bloc/clients_bloc.dart';

// Loans
import 'features/loans/domain/repositories/loans_repository.dart';
import 'features/loans/data/repositories/loans_repository_impl.dart';
import 'features/loans/presentation/bloc/loans_bloc.dart';

// Rentals
import 'package:app_prestaya_flutter/features/rentals/domain/repositories/rentals_repository.dart';
import 'package:app_prestaya_flutter/features/rentals/data/repositories/rentals_repository_impl.dart';
import 'package:app_prestaya_flutter/features/rentals/presentation/bloc/rentals_bloc.dart';

// Notifications
import 'package:app_prestaya_flutter/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:app_prestaya_flutter/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:app_prestaya_flutter/features/notifications/presentation/bloc/notifications_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Core / External
  if (!sl.isRegistered<FlutterSecureStorage>()) {
    sl.registerLazySingleton(() => const FlutterSecureStorage());
  }
  
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  
  if (!sl.isRegistered<Dio>()) {
    sl.registerLazySingleton(() => Dio());
  }

  if (!sl.isRegistered<gsign.GoogleSignIn>()) {
    sl.registerLazySingleton(() => gsign.GoogleSignIn(
      serverClientId: '1014571855006-e7h8pmlebp3aummncmnm67pcgauq1kqq.apps.googleusercontent.com',
    ));
  }

  // Stats
  sl.registerLazySingleton<stats_ds.StatsRemoteDataSource>(() => stats_ds.StatsRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<stats_repo.StatsRepository>(() => stats_repo.StatsRepositoryImpl(sl()));
  sl.registerFactory(() => stats_bloc.StatsBloc(repository: sl()));

  if (!sl.isRegistered<fln.FlutterLocalNotificationsPlugin>()) {
    sl.registerLazySingleton(() => fln.FlutterLocalNotificationsPlugin());
  }
  
  // Custom Dio Client
  if (!sl.isRegistered<DioClient>()) {
    sl.registerLazySingleton(() => DioClient(sl(), sl()));
  }

  // Features - Auth
  if (!sl.isRegistered<AuthBloc>()) {
    sl.registerFactory(() => AuthBloc(
          loginUseCase: sl(),
          uploadPhotoUseCase: sl(),
          repository: sl(),
        ));
  }
  
  if (!sl.isRegistered<LoginUseCase>()) {
    sl.registerLazySingleton(() => LoginUseCase(sl()));
  }
  
  if (!sl.isRegistered<UploadPhotoUseCase>()) {
    sl.registerLazySingleton(() => UploadPhotoUseCase(sl()));
  }

  if (!sl.isRegistered<AuthRepository>()) {
    sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(sl(), sl()),
    );
  }

  if (!sl.isRegistered<AuthRemoteDataSource>()) {
    sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(sl()),
    );
  }

  // Features - Clients
  if (!sl.isRegistered<ClientsBloc>()) {
    sl.registerFactory(() => ClientsBloc(
      getClientsUseCase: sl(),
      addClientUseCase: sl(),
      updateClientUseCase: sl(),
      deleteClientUseCase: sl(),
    ));
  }

  if (!sl.isRegistered<GetClientsUseCase>()) {
    sl.registerLazySingleton(() => GetClientsUseCase(sl()));
  }
  if (!sl.isRegistered<AddClientUseCase>()) {
    sl.registerLazySingleton(() => AddClientUseCase(sl()));
  }
  if (!sl.isRegistered<UpdateClientUseCase>()) {
    sl.registerLazySingleton(() => UpdateClientUseCase(sl()));
  }
  if (!sl.isRegistered<DeleteClientUseCase>()) {
    sl.registerLazySingleton(() => DeleteClientUseCase(sl()));
  }

  if (!sl.isRegistered<ClientRepository>()) {
    sl.registerLazySingleton<ClientRepository>(
      () => ClientRepositoryImpl(remoteDataSource: sl()),
    );
  }

  if (!sl.isRegistered<ClientRemoteDataSource>()) {
    sl.registerLazySingleton<ClientRemoteDataSource>(
      () => ClientRemoteDataSourceImpl(client: sl<DioClient>().dio),
    );
  }

  // Features - Loans
  if (!sl.isRegistered<LoansBloc>()) {
    sl.registerFactory(() => LoansBloc(repository: sl()));
  }

  if (!sl.isRegistered<LoansRepository>()) {
    sl.registerLazySingleton<LoansRepository>(
      () => LoansRepositoryImpl(dioClient: sl()),
    );
  }

  // Features - Rentals
  if (!sl.isRegistered<RentalsBloc>()) {
    sl.registerFactory(() => RentalsBloc(repository: sl()));
  }

  if (!sl.isRegistered<RentalsRepository>()) {
    sl.registerLazySingleton<RentalsRepository>(
      () => RentalsRepositoryImpl(dioClient: sl()),
    );
  }

  // Features - Notifications
  if (!sl.isRegistered<NotificationsBloc>()) {
    sl.registerFactory(() => NotificationsBloc(repository: sl()));
    sl.registerLazySingleton<NotificationsRepository>(() => NotificationsRepositoryImpl(dioClient: sl()));
  }

  //! Core
  if (!sl.isRegistered<ExportService>()) {
    sl.registerLazySingleton(() => ExportService(sl()));
  }
}
