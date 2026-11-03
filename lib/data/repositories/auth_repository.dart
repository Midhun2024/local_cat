import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

abstract class AuthRepository {
  Future<UserModel> loginWithUserId(int userId);
  Future<List<UserModel>> getAvailableMockUsers();
}

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this.apiService});

  final ApiService apiService;

  @override
  Future<UserModel> loginWithUserId(int userId) async {
    if (userId < AppConstants.minMockUserId ||
        userId > AppConstants.maxMockUserId) {
      throw ValidationException(
        'User ID must be between ${AppConstants.minMockUserId} and ${AppConstants.maxMockUserId}.',
      );
    }

    // Fetch the users from the API and select the matching user by ID
    final users = await apiService.getUsers();
    final matchingUser = users.where((u) => u.id == userId).firstOrNull;

    if (matchingUser == null) {
      throw UserNotFoundException(userId);
    }

    return matchingUser;
  }

  @override
  Future<List<UserModel>> getAvailableMockUsers() async {
    return apiService.getUsers();
  }
}
