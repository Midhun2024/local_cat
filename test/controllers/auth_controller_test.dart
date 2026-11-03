import 'package:flutter_test/flutter_test.dart';
import 'package:local_cat/controllers/auth_controller.dart';
import 'package:local_cat/core/errors/app_exception.dart';
import 'package:local_cat/data/models/user_model.dart';
import 'package:local_cat/data/repositories/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  UserModel? mockUser;
  bool shouldThrow = false;
  AppException? exceptionToThrow;

  @override
  Future<UserModel> loginWithUserId(int userId) async {
    if (shouldThrow) {
      throw exceptionToThrow ?? const ServerException(statusCode: 500);
    }
    if (mockUser != null) {
      return mockUser!;
    }
    return UserModel(
      id: userId,
      name: 'Test User $userId',
      username: 'test$userId',
      email: 'test$userId@example.com',
      phone: '123-456-7890',
      website: 'example.com',
      company: const CompanyModel(name: 'Test Company'),
    );
  }

  @override
  Future<List<UserModel>> getAvailableMockUsers() async {
    return [];
  }
}

void main() {
  group('AuthController', () {
    late FakeAuthRepository fakeRepo;
    late AuthController controller;

    setUp(() {
      fakeRepo = FakeAuthRepository();
      controller = AuthController(authRepository: fakeRepo);
    });

    test('initial state has no user, not loading, no error', () {
      expect(controller.currentUser, isNull);
      expect(controller.isAuthenticated, isFalse);
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
    });

    test('successful login sets currentUser and isAuthenticated', () async {
      final success = await controller.login(1);

      expect(success, isTrue);
      expect(controller.isAuthenticated, isTrue);
      expect(controller.currentUser!.id, 1);
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
    });

    test('failed login sets errorMessage and returns false', () async {
      fakeRepo.shouldThrow = true;
      fakeRepo.exceptionToThrow = const UserNotFoundException(99);

      final success = await controller.login(99);

      expect(success, isFalse);
      expect(controller.isAuthenticated, isFalse);
      expect(controller.currentUser, isNull);
      expect(
        controller.errorMessage,
        contains('User with ID 99 was not found'),
      );
      expect(controller.isLoading, isFalse);
    });

    test('logout clears user session', () async {
      await controller.login(1);
      expect(controller.isAuthenticated, isTrue);

      controller.logout();

      expect(controller.isAuthenticated, isFalse);
      expect(controller.currentUser, isNull);
      expect(controller.errorMessage, isNull);
    });

    test('clearError resets error message', () async {
      fakeRepo.shouldThrow = true;
      await controller.login(1);
      expect(controller.errorMessage, isNotNull);

      controller.clearError();
      expect(controller.errorMessage, isNull);
    });
  });
}
