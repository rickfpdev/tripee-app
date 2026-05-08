import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../errors/exceptions.dart';

class HttpClient {
  HttpClient._();

  static Dio? _instance;

  static Dio get instance {
    _instance ??= _buildDio();
    return _instance!;
  }

  static Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException e, handler) {
          switch (e.type) {
            case DioExceptionType.connectionTimeout:
            case DioExceptionType.receiveTimeout:
            case DioExceptionType.sendTimeout:
            case DioExceptionType.connectionError:
              handler.reject(
                DioException(
                  requestOptions: e.requestOptions,
                  error: const NetworkException(),
                  type: e.type,
                ),
              );
            case DioExceptionType.badResponse:
              final statusCode = e.response?.statusCode;
              if (statusCode == 404) {
                handler.reject(
                  DioException(
                    requestOptions: e.requestOptions,
                    error: const NotFoundException(),
                    type: e.type,
                    response: e.response,
                  ),
                );
              } else {
                handler.reject(
                  DioException(
                    requestOptions: e.requestOptions,
                    error: ServerException(statusCode: statusCode),
                    type: e.type,
                    response: e.response,
                  ),
                );
              }
            default:
              handler.next(e);
          }
        },
      ),
    );

    return dio;
  }

  static AppException handleDioException(DioException e) {
    if (e.error is AppException) return e.error as AppException;
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return const NetworkException();
    }
    return ServerException(statusCode: e.response?.statusCode);
  }
}
