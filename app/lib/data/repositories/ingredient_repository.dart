import 'dart:io';
import '../datasources/remote/api_client.dart';
import '../../core/config/api_config.dart';

class IngredientRepository {
  final ApiClient _apiClient;

  IngredientRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// 识别食材
  Future<Map<String, dynamic>> recognizeIngredients(File imageFile) async {
    final response = await _apiClient.uploadFile(
      ApiConfig.recognizeIngredients,
      imageFile.path,
      'file',
    );
    return response.data;
  }

  /// 获取识别历史
  Future<Map<String, dynamic>> getHistory() async {
    final response = await _apiClient.get(ApiConfig.ingredientHistory);
    return response.data;
  }
}
