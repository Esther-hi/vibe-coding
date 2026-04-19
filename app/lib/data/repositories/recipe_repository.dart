import 'package:dio/dio.dart';
import '../datasources/remote/api_client.dart';
import '../../core/config/api_config.dart';

class RecipeRepository {
  final ApiClient _apiClient;

  RecipeRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// 生成菜谱
  Future<Map<String, dynamic>> generateRecipes({
    required List<String> ingredients,
    int peopleCount = 2,
    Map<String, dynamic>? preferences,
    int count = 3,
  }) async {
    final response = await _apiClient.post(
      ApiConfig.generateRecipes,
      data: {
        'ingredients': ingredients,
        'people_count': peopleCount,
        'preferences': preferences,
        'count': count,
      },
    );
    return response.data;
  }

  /// 获取菜谱详情
  Future<Map<String, dynamic>> getRecipe(String recipeId) async {
    final response = await _apiClient.get(
      '${ApiConfig.generateRecipes.replaceAll('/generate', '')}/$recipeId',
    );
    return response.data;
  }

  /// 搜索菜谱
  Future<Map<String, dynamic>> searchRecipes(String query) async {
    final response = await _apiClient.get(
      ApiConfig.searchRecipes,
      queryParameters: {'query': query},
    );
    return response.data;
  }

  /// 收藏菜谱
  Future<Map<String, dynamic>> favoriteRecipe(String recipeId) async {
    final response = await _apiClient.post(
      ApiConfig.favoriteRecipe.replaceAll('{id}', recipeId),
    );
    return response.data;
  }

  /// 取消收藏菜谱
  Future<Map<String, dynamic>> unfavoriteRecipe(String recipeId) async {
    final response = await _apiClient.delete(ApiConfig.favoriteRecipe.replaceAll('{id}', recipeId));
    return response.data;
  }

  /// 获取收藏列表
  Future<Map<String, dynamic>> getFavorites() async {
    final response = await _apiClient.get(ApiConfig.favorites);
    return response.data;
  }
}
