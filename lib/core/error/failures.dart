class Failure {
  final String? message;
  const Failure([this.message]);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message]);
}

class NetworkFailure extends Failure {
  const NetworkFailure([String? message])
    : super(message ?? 'No internet or local network connection.');
}

class CacheFailure extends Failure {
  const CacheFailure([super.message]);
}

class AuthFailure extends Failure {
  const AuthFailure([String? message])
    : super(message ?? 'Authentication failed');
}
