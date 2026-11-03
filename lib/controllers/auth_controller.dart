import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController({required this.authRepository});

  final AuthRepository authRepository;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDisposed = false;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Attempts mock login using a User ID (1 to 10).
  Future<bool> login(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      final user = await authRepository.loginWithUserId(userId);
      _currentUser = user;
      _isLoading = false;
      _safeNotifyListeners();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      _safeNotifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred during login.';
      _isLoading = false;
      _safeNotifyListeners();
      return false;
    }
  }

  /// Clears in-memory authenticated user session.
  void logout() {
    _currentUser = null;
    _errorMessage = null;
    _isLoading = false;
    _safeNotifyListeners();
  }

  /// Clears any active error message.
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      _safeNotifyListeners();
    }
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
