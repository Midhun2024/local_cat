import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/auth_controller.dart';
import '../../views/categories/category_screen.dart';
import '../../views/login/login_screen.dart';
import '../../views/profile/profile_screen.dart';

class AppRouter {
  const AppRouter._();

  static const String loginRoute = '/login';
  static const String profileRoute = '/profile';
  static const String categoriesRoute = '/categories';

  static GoRouter createRouter(AuthController authController) {
    return GoRouter(
      initialLocation: loginRoute,
      refreshListenable: authController,
      redirect: (BuildContext context, GoRouterState state) {
        final isAuthenticated = authController.isAuthenticated;
        final isLoggingIn = state.matchedLocation == loginRoute;

        // If not authenticated and not currently on login page, force to login
        if (!isAuthenticated) {
          return isLoggingIn ? null : loginRoute;
        }

        // If authenticated and trying to access login page, redirect to profile
        if (isLoggingIn) {
          return profileRoute;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: loginRoute,
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: profileRoute,
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: categoriesRoute,
          name: 'categories',
          builder: (context, state) => const CategoryScreen(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(child: Text('Page not found: ${state.matchedLocation}')),
      ),
    );
  }
}
