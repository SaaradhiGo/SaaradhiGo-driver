// ignore_for_file: use_super_parameters

abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure([
    String message = 'Server error occurred, please try again.',
  ]) : super(message);
}

class AuthFailure extends Failure {
  const AuthFailure([
    String message = 'Authentication failed. Please login again.',
  ]) : super(message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    String message = 'No internet connection. Please check your network.',
  ]) : super(message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
}

class UnknownFailure extends Failure {
  const UnknownFailure([String message = 'An unknown error occurred.'])
    : super(message);
}
