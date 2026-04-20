import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/todo.dart';
import '../../data/repositories/todo_repository.dart';
import '../../data/datasources/local/local_storage.dart';
import 'api_client_provider.dart';

class TodoState {
  final List<TodoListModel> todoLists;
  final Map<String, List<TodoItem>> todoDetails;
  final bool isLoading;
  final String? error;

  TodoState({
    this.todoLists = const [],
    this.todoDetails = const {},
    this.isLoading = false,
    this.error,
  });

  TodoState copyWith({
    List<TodoListModel>? todoLists,
    Map<String, List<TodoItem>>? todoDetails,
    bool? isLoading,
    String? error,
  }) =>
      TodoState(
        todoLists: todoLists ?? this.todoLists,
        todoDetails: todoDetails ?? this.todoDetails,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class TodoNotifier extends StateNotifier<TodoState> {
  final TodoRepository _repo;
  final LocalStorage _localStorage;

  TodoNotifier(this._repo, this._localStorage) : super(TodoState()) {
    _loadFromLocal();
  }

  void _loadFromLocal() {
    // 清除旧的本地待办数据，避免残留
    _localStorage.saveLocalTodos([]);
    loadTodoLists();
  }

  Future<void> loadTodoLists() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _repo.getTodoLists();
      final List list = response['data'] ?? [];
      final todos = list.map((e) => TodoListModel.fromJson(e)).toList();
      state = state.copyWith(todoLists: todos, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<String?> createTodo(
    List<String> recipeNames,
    String servings,
    List<Map<String, dynamic>> items,
  ) async {
    // 先本地保存，确保即时可用
    final todoId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final localTodo = {
      'id': todoId,
      'recipe_names': recipeNames,
      'servings': servings,
      'status': 'pending',
      'total_items': items.length,
      'pending_items': items.length,
    };

    // 保存待办列表
    final currentTodos = _localStorage.getLocalTodos();
    currentTodos.insert(0, localTodo);
    await _localStorage.saveLocalTodos(currentTodos);

    // 保存待办明细
    final detailKey = 'todo_detail_$todoId';
    final detailList = items.map((item) => {
      'id': '${todoId}_${item['name']}',
      'ingredient_name': item['name'],
      'quantity': item['quantity'],
      'is_purchased': false,
    }).toList();
    final encoded = '[${detailList.map((e) => '{"id":"${e['id']}","ingredient_name":"${e['ingredient_name']}","quantity":"${e['quantity']}","is_purchased":false}').join(',')}]';
    await _localStorage.saveUserData({detailKey: encoded});

    // 更新 state
    final todos = currentTodos.map((e) => TodoListModel.fromJson(e)).toList();
    final newDetails = Map<String, List<TodoItem>>.from(state.todoDetails);
    newDetails[todoId] = detailList.map((e) => TodoItem(
      id: e['id'] as String,
      ingredientName: e['ingredient_name'] as String,
      quantity: e['quantity'] as String,
    )).toList();
    state = state.copyWith(todoLists: todos, todoDetails: newDetails);

    // 后台尝试同步到后端
    _syncToBackend(recipeNames, servings, items);

    return todoId;
  }

  Future<void> _syncToBackend(
    List<String> recipeNames,
    String servings,
    List<Map<String, dynamic>> items,
  ) async {
    try {
      await _repo.createTodo(
        recipeNames: recipeNames,
        servings: servings,
        items: items,
      );
    } catch (_) {
      // 后端不可用，本地已保存，忽略
    }
  }

  Future<List<TodoItem>?> loadTodoDetail(String todoId) async {
    if (state.todoDetails.containsKey(todoId)) {
      return state.todoDetails[todoId];
    }
    try {
      final response = await _repo.getTodoDetail(todoId);
      final List list = response['data']?['items'] ?? [];
      final items = list.map((e) => TodoItem.fromJson(e)).toList();
      final newDetails = Map<String, List<TodoItem>>.from(state.todoDetails);
      newDetails[todoId] = items;
      state = state.copyWith(todoDetails: newDetails);
      return items;
    } catch (_) {
      return null;
    }
  }

  Future<void> toggleItem(String todoId, String itemId, bool isPurchased) async {
    // 先更新本地 state
    final newDetails = Map<String, List<TodoItem>>.from(state.todoDetails);
    final items = (newDetails[todoId] ?? []).map((e) {
      if (e.id == itemId) return e.copyWith(isPurchased: isPurchased);
      return e;
    }).toList();
    newDetails[todoId] = items;

    // 更新列表的 pendingItems
    final newLists = state.todoLists.map((t) {
      if (t.id == todoId) {
        return TodoListModel(
          id: t.id,
          recipeNames: t.recipeNames,
          servings: t.servings,
          status: t.status,
          totalItems: t.totalItems,
          pendingItems: items.where((e) => !e.isPurchased).length,
        );
      }
      return t;
    }).toList();
    state = state.copyWith(todoLists: newLists, todoDetails: newDetails);

    try {
      await _repo.toggleTodoItem(itemId, isPurchased: isPurchased);
    } catch (_) {}
  }

  Future<void> deleteTodo(String todoId) async {
    // 先从本地移除
    final currentTodos = _localStorage.getLocalTodos();
    currentTodos.removeWhere((e) => e['id'] == todoId);
    await _localStorage.saveLocalTodos(currentTodos);

    final newLists = state.todoLists.where((t) => t.id != todoId).toList();
    state = state.copyWith(todoLists: newLists);

    try {
      await _repo.deleteTodo(todoId);
    } catch (_) {}
  }

  Future<void> updateStatus(String todoId, String status) async {
    final newLists = state.todoLists.map((t) {
      if (t.id == todoId) {
        return TodoListModel(
          id: t.id,
          recipeNames: t.recipeNames,
          servings: t.servings,
          status: status,
          totalItems: t.totalItems,
          pendingItems: t.pendingItems,
        );
      }
      return t;
    }).toList();
    state = state.copyWith(todoLists: newLists);

    try {
      await _repo.updateTodoStatus(todoId, status);
    } catch (_) {}
  }
}

final todoProvider = StateNotifierProvider<TodoNotifier, TodoState>(
  (ref) => TodoNotifier(
    TodoRepository(apiClient: ref.watch(apiClientProvider)),
    ref.watch(localStorageProvider),
  ),
);
