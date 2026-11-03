import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_cat/controllers/auth_controller.dart';
import 'package:local_cat/data/models/user_model.dart';
import 'package:local_cat/data/repositories/auth_repository.dart';
import 'package:local_cat/views/profile/profile_screen.dart';
import 'package:provider/provider.dart';

class MockAuthRepo implements AuthRepository {
  @override
  Future<UserModel> loginWithUserId(int userId) async {
    return UserModel(
      id: 1,
      name: 'Leanne Graham',
      username: 'Bret',
      email: 'Sincere@april.biz',
      phone: '1-770-736-8031',
      website: 'hildegard.org',
      company: const CompanyModel(
        name: 'Romaguera-Crona',
        catchPhrase: 'Multi-layered neural-net',
      ),
    );
  }

  @override
  Future<List<UserModel>> getAvailableMockUsers() async => [];
}

void main() {
  Widget createWidgetUnderTest(AuthController controller) {
    return ChangeNotifierProvider<AuthController>.value(
      value: controller,
      child: const MaterialApp(home: ProfileScreen()),
    );
  }

  group('ProfileScreen Widget Tests', () {
    late AuthController authController;

    setUp(() {
      authController = AuthController(authRepository: MockAuthRepo());
    });

    testWidgets('displays real user data when authenticated', (tester) async {
      await authController.login(1);
      await tester.pumpWidget(createWidgetUnderTest(authController));
      await tester.pumpAndSettle();

      expect(find.text('Leanne Graham'), findsOneWidget);
      expect(find.text('@Bret (ID: 1)'), findsOneWidget);
      expect(find.text('Sincere@april.biz'), findsOneWidget);
      expect(find.text('1-770-736-8031'), findsOneWidget);
      expect(find.text('hildegard.org'), findsOneWidget);
      expect(find.text('Romaguera-Crona'), findsOneWidget);
      expect(find.text('Multi-layered neural-net'), findsOneWidget);
      expect(find.text('Manage Categories'), findsOneWidget);
    });

    testWidgets('shows confirmation dialog when logout is tapped', (
      tester,
    ) async {
      await authController.login(1);
      await tester.pumpWidget(createWidgetUnderTest(authController));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithIcon(IconButton, Icons.logout));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Logout'), findsOneWidget);
      expect(
        find.text('Are you sure you want to end your session?'),
        findsOneWidget,
      );
      expect(find.text('Logout'), findsOneWidget);
    });
  });
}
