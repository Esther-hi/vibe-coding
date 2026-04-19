import 'package:dio/dio.dart';
import '../../../core/config/api_config.dart';
import '../local/local_storage.dart';

class ApiClient {
  late final Dio _dio;
  final LocalStorage _localStorage;

  ApiClient({LocalStorage? localStorage}) : _localStorage = localStorage ?? LocalStorage() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: Duration(milliseconds: ApiConfig.connectTimeout),
        receiveTimeout: Duration(milliseconds: ApiConfig.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    // 添加拦截器
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 从本地存储获取 Token
          final token = await _localStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          // 处理 401 等错误
          if (error.response?.statusCode == 401) {
            // Token 过期，需要重新登录
            _localStorage.clearToken();
          }
          return handler.next(error);
        },
      ),
    );
  }

  // 暴露 dio 实例供上传文件使用
  Dio get dio => _dio;

  // GET 请求
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  // POST 请求
  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  // PUT 请求
  Future<Response> put(String path, {dynamic data}) async {
    return await _dio.put(path, data: data);
  }

  // DELETE 请求
  Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }

  // 上传文件
  Future<Response> uploadFile(String path, String filePath, String fieldName) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(filePath),
    });
    return await _dio.post(path, data: formData);
  }
}
