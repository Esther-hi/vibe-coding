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

  Future<Map<String, dynamic>> sendCode({required String phone, String purpose = 'register'}) async {
    final response = await _apiClient.post(ApiConfig.sendCode, data: {'phone': phone, 'purpose': purpose});
    return response.data;
  }

  Future<Map<String, dynamic>> loginWithPhone({required String phone, required String code}) async {
    final response = await _apiClient.post(ApiConfig.login, data: {'phone': phone, 'code': code});
    return response.data;
  }

  Future<Map<String, dynamic>> loginWithPassword({required String username, required String password}) async {
    final response = await _apiClient.post(ApiConfig.login, data: {'username': username, 'password': password});
    return response.data;
  }

  Future<Map<String, dynamic>> registerWithPhone({required String username, required String phone, required String code, required String password}) async {
    final response = await _apiClient.post(ApiConfig.register, data: {'username': username, 'phone': phone, 'code': code, 'password': password});
    return response.data;
  }

  Future<Map<String, dynamic>> resetPassword({required String phone, required String code, required String newPassword}) async {
    final response = await _apiClient.post(ApiConfig.resetPassword, data: {'phone': phone, 'code': code, 'new_password': newPassword});
    return response.data;
  }
}
