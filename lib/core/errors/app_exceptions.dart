/// Base exception for all app errors.
abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => 'AppException: $message';
}

class AuthException extends AppException {
  const AuthException([super.message = 'Authentication failed']);
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Network error occurred']);
}

class GitOperationException extends AppException {
  const GitOperationException([super.message = 'Git operation failed']);
}

class ConflictException extends AppException {
  const ConflictException([super.message = 'Conflict detected']);
}

class FileNotFoundException extends AppException {
  final String path;
  const FileNotFoundException(this.path)
      : super('File not found: $path');
}

class ValidationException extends AppException {
  const ValidationException([super.message = 'Validation failed']);
}
