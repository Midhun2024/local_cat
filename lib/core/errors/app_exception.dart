/// Base class for application-specific exceptions.
abstract class AppException implements Exception {
  const AppException(this.message, [this.details]);

  final String message;
  final Object? details;

  @override
  String toString() {
    if (details != null) {
      return '$message ($details)';
    }
    return message;
  }
}

/// Thrown when a network connection fails or the device is offline.
class NetworkException extends AppException {
  const NetworkException([
    super.message =
        'Unable to connect to the server. Please check your internet connection.',
    super.details,
  ]);
}

/// Thrown when a network request times out.
class TimeoutAppException extends AppException {
  const TimeoutAppException([
    super.message = 'The request timed out. Please try again.',
    super.details,
  ]);
}

/// Thrown when a remote server returns an error response code.
class ServerException extends AppException {
  const ServerException({
    required this.statusCode,
    String? message,
    Object? details,
  }) : super(
         message ?? 'Server responded with error status code $statusCode.',
         details,
       );

  final int statusCode;
}

/// Thrown when parsing API responses or serialized data fails.
class DataParsingException extends AppException {
  const DataParsingException([
    super.message = 'Failed to parse response data.',
    super.details,
  ]);
}

/// Thrown when the requested mock user does not exist.
class UserNotFoundException extends AppException {
  const UserNotFoundException(int userId)
    : super('User with ID $userId was not found.');
}

/// Thrown when attempting to add a category with a duplicate name under the same parent.
class DuplicateCategoryException extends AppException {
  const DuplicateCategoryException(String name, [int? parentId])
    : super(
        parentId == null
            ? 'A root category named "$name" already exists.'
            : 'A subcategory named "$name" already exists under this parent.',
      );
}

/// Thrown when a referenced category does not exist.
class CategoryNotFoundException extends AppException {
  const CategoryNotFoundException(int id)
    : super('Category with ID $id was not found.');
}

/// Thrown when an error occurs during local SQLite database operations.
class DatabaseAppException extends AppException {
  const DatabaseAppException([
    super.message = 'An unexpected database error occurred.',
    super.details,
  ]);
}

/// Thrown when input validation fails.
class ValidationException extends AppException {
  const ValidationException(super.message, [super.details]);
}
