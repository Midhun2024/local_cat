import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/category_controller.dart';
import '../core/constants/app_constants.dart';
import '../di/service_locator.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class CategoryManagerApp extends StatefulWidget {
  const CategoryManagerApp({super.key});

  @override
  State<CategoryManagerApp> createState() => _CategoryManagerAppState();
}

class _CategoryManagerAppState extends State<CategoryManagerApp> {
  late final AuthController _authController;
  late final CategoryController _categoryController;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authController = sl<AuthController>();
    _categoryController = sl<CategoryController>();
    _router = AppRouter.createRouter(_authController);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: _authController),
        ChangeNotifierProvider<CategoryController>.value(
          value: _categoryController,
        ),
      ],
      child: MaterialApp.router(
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
