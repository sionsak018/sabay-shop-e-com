class ServerException implements Exception {
  final String? message;
  final int? statusCode;

  ServerException({this.message, this.statusCode});
}

class CacheException implements Exception {}

class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);
}
