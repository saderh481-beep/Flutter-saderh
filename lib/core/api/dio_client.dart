import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../auth/secure_storage.dart';
import '../auth/auth_provider.dart';
import 'api_endpoints.dart';

class DioClient {
  late final Dio dio;
  final AuthProvider _authProvider;

  DioClient(this._authProvider) {
    dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(_authInterceptor());
    dio.interceptors.add(_logInterceptor());
    dio.interceptors.add(_errorInterceptor());
  }

  Interceptor _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecureStorage.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        final baseUrl = await SecureStorage.getServerUrl();
        if (baseUrl.isNotEmpty) {
          options.baseUrl = baseUrl;
        }

        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 &&
            error.requestOptions.path != ApiEndpoints.authLogin &&
            error.requestOptions.path != ApiEndpoints.authLogout) {
          await SecureStorage.clearAll();
          _authProvider.logout();
          handler.reject(error);
          return;
        }
        handler.next(error);
      },
    );
  }

  Interceptor _logInterceptor() {
    return LogInterceptor(
      request: kDebugMode,
      requestHeader: kDebugMode,
      requestBody: kDebugMode,
      responseHeader: kDebugMode,
      responseBody: kDebugMode,
      error: kDebugMode,
    );
  }

  Interceptor _errorInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) {
        if (error.response?.statusCode == 429) {
          handler.reject(DioException(
            requestOptions: error.requestOptions,
            type: DioExceptionType.badResponse,
            response: error.response,
            message: 'Demasiadas solicitudes. Intenta de nuevo en un momento.',
          ));
          return;
        }
        handler.next(error);
      },
    );
  }
}
