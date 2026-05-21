import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/secure_storage.dart';

final secureStorageProvider = Provider((ref) => SecureStorage());

const _defaultApiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://10.0.2.2:3000/api',
);

final dioProvider = Provider((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: _defaultApiUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  final storage = ref.watch(secureStorageProvider);

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await storage.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        final isRetry = error.requestOptions.extra['_retry'] == true;
        final path = error.requestOptions.path;

        if (!isRetry && !path.startsWith('/auth/')) {
          final refreshToken = await storage.getRefreshToken();
          if (refreshToken != null && refreshToken.isNotEmpty) {
            try {
              // Use a bare Dio to avoid interceptor loop
              final refreshDio = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
              final res = await refreshDio.post(
                '/auth/refresh',
                data: {'refreshToken': refreshToken},
              );
              final newAccessToken = res.data['accessToken'] as String;
              final newRefreshToken = res.data['refreshToken'] as String;
              await storage.saveTokens(
                accessToken: newAccessToken,
                refreshToken: newRefreshToken,
              );

              // Retry the original request with the new access token
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $newAccessToken';
              opts.extra['_retry'] = true;
              final retryResponse = await dio.fetch(opts);
              return handler.resolve(retryResponse);
            } on DioException catch (_) {
              // Refresh failed — fall through to clear session
            }
          }
        }

        await storage.clearTokens();
      }
      return handler.next(error);
    },
  ));

  return dio;
});

class ApiClient {
  final Dio _dio;

  ApiClient(this._dio);

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(String path, {dynamic data}) {
    return _dio.post<T>(path, data: data);
  }

  Future<Response<T>> patch<T>(String path, {dynamic data}) {
    return _dio.patch<T>(path, data: data);
  }

  Future<Response<T>> put<T>(String path, {dynamic data}) {
    return _dio.put<T>(path, data: data);
  }

  Future<Response<T>> delete<T>(String path) {
    return _dio.delete<T>(path);
  }
}

final apiClientProvider = Provider((ref) => ApiClient(ref.watch(dioProvider)));
