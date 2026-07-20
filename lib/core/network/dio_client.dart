import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DioClient {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  static const String tokenKey = '@auth_token';
  static const String refreshTokenKey = '@refresh_token';

  DioClient(this._dio, this._storage) {
    _dio
      ..options.baseUrl = 'https://servicio.teamrecios.com/api'
      ..options.connectTimeout = const Duration(seconds: 30)
      ..options.receiveTimeout = const Duration(seconds: 30)
      ..options.responseType = ResponseType.json
      ..interceptors.add(_getAuthInterceptor());
  }

  bool _isRefreshing = false;
  final List<Map<String, dynamic>> _failedRequests = [];

  Interceptor _getAuthInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (options.path.contains('/auth/login') || options.path.contains('/auth/refresh')) {
          return handler.next(options);
        }

        final token = await _storage.read(key: tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401 && !e.requestOptions.path.contains('/auth/refresh')) {
          final refreshToken = await _storage.read(key: refreshTokenKey);
          if (refreshToken == null) {
            await _clearSession();
            return handler.next(e);
          }

          if (!_isRefreshing) {
            _isRefreshing = true;
            try {
              final newDio = Dio(BaseOptions(baseUrl: _dio.options.baseUrl));
              final response = await newDio.post('/auth/refresh', data: {
                'refreshToken': refreshToken,
              });

              final newToken = response.data['token'];
              final newRefreshToken = response.data['refreshToken'];

              await _storage.write(key: tokenKey, value: newToken);
              if (newRefreshToken != null) {
                await _storage.write(key: refreshTokenKey, value: newRefreshToken);
              }

              _dio.options.headers['Authorization'] = 'Bearer $newToken';
              e.requestOptions.headers['Authorization'] = 'Bearer $newToken';
              
              for (var request in _failedRequests) {
                request['options'].headers['Authorization'] = 'Bearer $newToken';
                _dio.fetch(request['options']).then(
                  (res) => request['handler'].resolve(res),
                  onError: (err) => request['handler'].reject(err),
                );
              }
              _failedRequests.clear();
              _isRefreshing = false;

              final retryResponse = await _dio.fetch(e.requestOptions);
              return handler.resolve(retryResponse);
            } catch (err) {
              _isRefreshing = false;
              _failedRequests.clear();
              await _clearSession();
              return handler.next(e);
            }
          } else {
            _failedRequests.add({'options': e.requestOptions, 'handler': handler});
            return; // Esperar a que el refresh termine
          }
        }
        return handler.next(e);
      },
    );
  }

  Future<void> _clearSession() async {
    await _storage.delete(key: tokenKey);
    await _storage.delete(key: refreshTokenKey);
    await _storage.delete(key: '@user_profile');
  }

  Dio get dio => _dio;

  // Mtodo para aadir el token dinmicamente
  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Mtodo genrico para GET
  Future<Response> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.get(
        url,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Mtodo genrico para POST
  Future<Response> post(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.post(
        url,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Método genérico para PUT
  Future<Response> put(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.put(
        url,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Método genérico para DELETE
  Future<Response> delete(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete(
        url,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Método genérico para PATCH
  Future<Response> patch(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.patch(
        url,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
  // Método para descargar bytes (archivos)
  Future<List<int>> downloadBytes(String url, Map<String, dynamic>? queryParameters) async {
    try {
      final response = await _dio.get<List<int>>(
        url,
        queryParameters: queryParameters,
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data!;
    } catch (e) {
      rethrow;
    }
  }
}
