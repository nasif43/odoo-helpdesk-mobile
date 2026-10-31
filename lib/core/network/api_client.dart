import 'package:dio/dio.dart';
import '../storage/token_storage.dart';
import '../errors/failures.dart';

class ApiClient {
  static const String permanentServerUrl = 'https://tender.metamorphosis.com.bd';

  static String get defaultBaseUrl {
    // 24/7 dedicated production/demo endpoint on tender-server
    return '$permanentServerUrl/api/mobile/v1';
  }

  final Dio dio;
  final TokenStorage tokenStorage;

  ApiClient({String? baseUrl, TokenStorage? storage})
      : dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? defaultBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'X-Odoo-Database': 'odoo_helpdesk_db',
          },
        )),
        tokenStorage = storage ?? TokenStorage() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // Automatic token refresh on 401
          if (e.response?.statusCode == 401 && !e.requestOptions.path.contains('/auth/')) {
            final refreshToken = await tokenStorage.getRefreshToken();
            if (refreshToken != null) {
              try {
                final refreshRes = await dio.post(
                  '/auth/refresh',
                  data: {'refresh_token': refreshToken},
                  options: Options(headers: {}),
                );
                if (refreshRes.statusCode == 200 && refreshRes.data['ok'] == true) {
                  final data = refreshRes.data['data'];
                  await tokenStorage.saveTokens(
                    accessToken: data['access_token'],
                    refreshToken: data['refresh_token'],
                    role: data['user']['role'],
                    userId: data['user']['id'],
                    userName: data['user']['name'],
                  );
                  // Retry the original request
                  final retryOptions = e.requestOptions;
                  retryOptions.headers['Authorization'] = 'Bearer ${data['access_token']}';
                  final cloneReq = await dio.fetch(retryOptions);
                  return handler.resolve(cloneReq);
                }
              } catch (_) {
                await tokenStorage.clear();
              }
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  Failure mapDioError(DioException e) {
    if (e.response != null && e.response?.data is Map) {
      final data = e.response!.data as Map;
      if (data['error'] is Map) {
        final err = data['error'] as Map;
        return Failure(
          err['message']?.toString() ?? 'An error occurred',
          code: err['code']?.toString(),
          fields: err['fields'] is Map ? Map<String, dynamic>.from(err['fields']) : null,
        );
      }
    }
    return NetworkFailure(e.message ?? 'Network connection error');
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) {
    return dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: headers != null ? Options(headers: headers) : null,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) {
    return dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: headers != null ? Options(headers: headers) : null,
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) {
    return dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: headers != null ? Options(headers: headers) : null,
    );
  }
}
