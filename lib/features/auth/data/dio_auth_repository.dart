import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/auth_repository.dart';
import '../domain/user.dart';

class DioAuthRepository implements AuthRepository {
  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  DioAuthRepository({ApiClient? client, TokenStorage? storage})
      : apiClient = client ?? ApiClient(),
        tokenStorage = storage ?? TokenStorage();

  @override
  Future<User> login(String email, String password) async {
    try {
      final res = await apiClient.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final data = res.data['data'];
      final user = User.fromJson(data['user']);
      await tokenStorage.saveTokens(
        accessToken: data['access_token'],
        refreshToken: data['refresh_token'],
        role: user.role,
        userId: user.id,
        userName: user.name,
      );
      return user;
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<User> register(String name, String email, String password, String phone) async {
    try {
      final res = await apiClient.dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
      });
      final data = res.data['data'];
      final user = User.fromJson(data['user']);
      await tokenStorage.saveTokens(
        accessToken: data['access_token'],
        refreshToken: data['refresh_token'],
        role: user.role,
        userId: user.id,
        userName: user.name,
      );
      return user;
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      final refreshToken = await tokenStorage.getRefreshToken();
      await apiClient.dio.post('/auth/logout', data: {
        'refresh_token': refreshToken,
      });
    } catch (_) {
      // Ignored on logout
    } finally {
      await tokenStorage.clear();
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    final token = await tokenStorage.getAccessToken();
    if (token == null) return null;
    try {
      final res = await apiClient.dio.get('/me');
      return User.fromJson(res.data['data']);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      await apiClient.dio.post('/auth/forgot-password', data: {'email': email});
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }

  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      await apiClient.dio.post('/auth/change-password', data: {
        'old_password': oldPassword,
        'new_password': newPassword,
      });
    } on DioException catch (e) {
      throw apiClient.mapDioError(e);
    }
  }
}
