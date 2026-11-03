import '../constants/app_constants.dart';

class Validators {
  const Validators._();

  /// Validates mock user ID input (integer between minMockUserId and maxMockUserId).
  static String? validateUserId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a user ID.';
    }

    final trimmed = value.trim();
    final parsed = int.tryParse(trimmed);
    if (parsed == null) {
      return 'User ID must be a valid integer.';
    }

    if (parsed < AppConstants.minMockUserId ||
        parsed > AppConstants.maxMockUserId) {
      return 'User ID must be between ${AppConstants.minMockUserId} and ${AppConstants.maxMockUserId}.';
    }

    return null;
  }

  /// Validates category name input.
  static String? validateCategoryName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Category name cannot be empty.';
    }

    final trimmed = value.trim();
    if (trimmed.length > 80) {
      return 'Category name cannot exceed 80 characters.';
    }

    return null;
  }

  /// Normalizes category name for case-insensitive and whitespace-trimmed comparison.
  static String normalizeCategoryName(String name) {
    return name.trim().toLowerCase();
  }
}
