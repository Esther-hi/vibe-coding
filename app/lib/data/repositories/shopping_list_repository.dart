import '../datasources/remote/api_client.dart';
import '../../core/config/api_config.dart';

class ShoppingListRepository {
  final ApiClient _apiClient;

  ShoppingListRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// 生成购物清单
  Future<Map<String, dynamic>> generateShoppingList({
    required String recipeName,
    required List<Map<String, dynamic>> missingIngredients,
    required List<String> availableIngredients,
  }) async {
    final response = await _apiClient.post(
      ApiConfig.generateShoppingList,
      data: {
        'recipe_name': recipeName,
        'missing_ingredients': missingIngredients,
        'available_ingredients': availableIngredients,
      },
    );
    return response.data;
  }

  /// 获取购物清单
  Future<Map<String, dynamic>> getShoppingList() async {
    final response = await _apiClient.get(ApiConfig.shoppingList);
    return response.data;
  }

  /// 更新购物项状态
  Future<Map<String, dynamic>> updateItem(String itemId, {bool isPurchased = true}) async {
    final response = await _apiClient.put(
      '${ApiConfig.shoppingList}/$itemId',
      data: {'is_purchased': isPurchased},
    );
    return response.data;
  }

  /// 删除购物项
  Future<Map<String, dynamic>> deleteItem(String itemId) async {
    final response = await _apiClient.delete('${ApiConfig.shoppingList}/$itemId');
    return response.data;
  }
}
