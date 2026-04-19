import 'package:dio/dio.dart';
import '../datasources/remote/api_client.dart';
import '../../core/config/api_config.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// 用户注册
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiConfig.register,
      data: {
        'username': username,
        'email': email,
        'password': password,
      },
    );
    return response.data;
  }

  /// 用户登录
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiConfig.login,
      data: {
        'username': username,
        'password': password,
      },
    );
    return response.data;
  }

  /// 获取当前用户信息
  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _apiClient.get(ApiConfig.currentUser);
    return response.data;
  }
}
