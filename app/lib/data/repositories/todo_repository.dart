import '../datasources/remote/api_client.dart';
import '../../core/config/api_config.dart';

class TodoRepository {
  final ApiClient _apiClient;

  TodoRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> getTodoLists() async {
    final response = await _apiClient.get(ApiConfig.todoList);
    return response.data;
  }

  Future<Map<String, dynamic>> getTodoDetail(String todoId) async {
    final response = await _apiClient.get('${ApiConfig.todoList}/$todoId');
    return response.data;
  }

  Future<Map<String, dynamic>> createTodo({
    required List<String> recipeNames,
    required String servings,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await _apiClient.post(ApiConfig.todoList, data: {
      'recipe_names': recipeNames,
      'servings': servings,
      'items': items,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> toggleTodoItem(String itemId, {bool isPurchased = true}) async {
    final response = await _apiClient.put(
      '${ApiConfig.todoList}/item/$itemId',
      data: {'is_purchased': isPurchased},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updateTodoStatus(String todoId, String status) async {
    final response = await _apiClient.put(
      '${ApiConfig.todoList}/$todoId/status',
      data: {'status': status},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> deleteTodo(String todoId) async {
    final response = await _apiClient.delete('${ApiConfig.todoList}/$todoId');
    return response.data;
  }
}
