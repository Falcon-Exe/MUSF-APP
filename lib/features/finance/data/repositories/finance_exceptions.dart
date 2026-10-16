// lib/features/finance/data/repositories/finance_exceptions.dart

class FinanceException implements Exception {
  final String message;
  FinanceException(this.message);
  @override
  String toString() => message;
}

class UnauthenticatedException extends FinanceException {
  UnauthenticatedException() : super('User is not authenticated.');
}

class PermissionDeniedException extends FinanceException {
  PermissionDeniedException() : super('Access denied. Administrator privileges required.');
}

class ValidationException extends FinanceException {
  ValidationException(String message) : super('Validation Error: $message');
}
