import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_cat/controllers/auth_controller.dart';
import 'package:local_cat/core/errors/app_exception.dart';
import 'package:local_cat/data/models/user_model.dart';
import 'package:local_cat/data/repositories/auth_repository.dart';
import 'package:local_cat/views/login/login_screen.dart';
import 'package:provider/provider.dart';

class MockAuthRepo implements AuthRepository {
  bool shouldFail = false;
  int? lastLoggedInId;

  @override
  Future<UserModel> loginWithUserId(int userId) async {
    lastLoggedInId = userId;
    if (shouldFail) {
      throw const UserNotFoundException(99);
    }
    return UserModel(
      id: userId,
      name: 'Leanne Graham',
      username: 'Bret',
      email: 'sincere@april.biz',
      phone: '123-456-7890',
      website: 'hildegard.org',
      company: const CompanyModel(name: 'Romaguera-Crona'),
    );
  }

  @override
  Future<List<UserModel>> getAvailableMockUsers() async => [];
}

void main() {
  Widget createWidgetUnderTest(AuthController controller) {
    return ChangeNotifierProvider<AuthController>.value(
      value: controller,
      child: const MaterialApp(home: LoginScreen()),
    );
  }

  group('LoginScreen Widget Tests', () {
    late MockAuthRepo mockRepo;
    late AuthController authController;

    setUp(() {
      mockRepo = MockAuthRepo();
      authController = AuthController(authRepository: mockRepo);
    });

    testWidgets('renders all initial login elements correctly', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(authController));

      expect(find.text('Welcome to Category Manager'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('shows validation error when submitted empty', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(authController));

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a user ID.'), findsOneWidget);
      expect(mockRepo.lastLoggedInId, isNull);
    });

    testWidgets('shows validation error for invalid ID numbers', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest(authController));

      await tester.enterText(find.byType(TextFormField), '15');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('User ID must be between 1 and 10.'), findsOneWidget);
      expect(mockRepo.lastLoggedInId, isNull);
    });

    testWidgets('calls login with valid ID 1-10', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(authController));

      await tester.enterText(find.byType(TextFormField), '3');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(mockRepo.lastLoggedInId, 3);
    });

    testWidgets('displays error banner when login fails', (tester) async {
      mockRepo.shouldFail = true;
      await tester.pumpWidget(createWidgetUnderTest(authController));

      await tester.enterText(find.byType(TextFormField), '5');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('User with ID 99 was not found'),
        findsOneWidget,
      );
    });
  });
}
