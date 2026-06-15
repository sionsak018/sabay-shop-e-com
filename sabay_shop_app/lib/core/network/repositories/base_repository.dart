import 'package:dio/dio.dart';
import 'package:sabay_shop_app/core/network/error/exceptions.dart';
import 'package:sabay_shop_app/core/network/error/failures.dart';

abstract class BaseRepository {
  Future<T> mapException<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      if (e.response != null) {
        throw ServerFailure(e.response?.data?['message'] ?? 'Server Error');
      } else {
        throw const ServerFailure('Network Error');
      }
    } on ServerException catch (e) {
      throw ServerFailure(e.message ?? 'Server Error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
