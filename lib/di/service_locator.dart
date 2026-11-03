import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import '../controllers/auth_controller.dart';
import '../controllers/category_controller.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/services/api_service.dart';
import '../data/services/database_service.dart';

final GetIt sl = GetIt.instance;

/// Sets up the service locator with all singletons, services, repositories, and controllers.
Future<void> setupServiceLocator({
  http.Client? httpClient,
  ApiService? apiService,
  DatabaseService? databaseService,
  AuthRepository? authRepository,
  CategoryRepository? categoryRepository,
}) async {
  // 1. External dependencies
  if (httpClient != null) {
    sl.registerSingleton<http.Client>(httpClient);
  } else if (!sl.isRegistered<http.Client>()) {
    sl.registerLazySingleton<http.Client>(() => http.Client());
  }

  // 2. Services
  if (apiService != null) {
    sl.registerSingleton<ApiService>(apiService);
  } else if (!sl.isRegistered<ApiService>()) {
    sl.registerLazySingleton<ApiService>(
      () => ApiService(client: sl<http.Client>()),
    );
  }

  if (databaseService != null) {
    sl.registerSingleton<DatabaseService>(databaseService);
  } else if (!sl.isRegistered<DatabaseService>()) {
    sl.registerLazySingleton<DatabaseService>(() => DatabaseService());
  }

  // 3. Repositories
  if (authRepository != null) {
    sl.registerSingleton<AuthRepository>(authRepository);
  } else if (!sl.isRegistered<AuthRepository>()) {
    sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(apiService: sl<ApiService>()),
    );
  }

  if (categoryRepository != null) {
    sl.registerSingleton<CategoryRepository>(categoryRepository);
  } else if (!sl.isRegistered<CategoryRepository>()) {
    sl.registerLazySingleton<CategoryRepository>(
      () => CategoryRepositoryImpl(databaseService: sl<DatabaseService>()),
    );
  }

  // 4. Controllers (registered as singletons or factories)
  if (!sl.isRegistered<AuthController>()) {
    sl.registerLazySingleton<AuthController>(
      () => AuthController(authRepository: sl<AuthRepository>()),
    );
  }

  if (!sl.isRegistered<CategoryController>()) {
    sl.registerLazySingleton<CategoryController>(
      () => CategoryController(categoryRepository: sl<CategoryRepository>()),
    );
  }
}

/// Resets all registered instances (useful in test teardown).
Future<void> resetServiceLocator() async {
  await sl.reset();
}
