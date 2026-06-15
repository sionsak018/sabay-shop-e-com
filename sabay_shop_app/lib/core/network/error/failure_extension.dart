import 'failures.dart';

extension FailureExtension on Failure {
  String get toMessage {
    if (this is ServerFailure) {
      return message;
    } else if (this is CacheFailure) {
      return 'Cache Error occurred';
    } else if (this is SecurityFailure) {
      return message;
    }
    return 'An unexpected error occurred';
  }
}
