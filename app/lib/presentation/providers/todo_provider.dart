import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/todo.dart';
import '../../data/repositories/todo_repository.dart';
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

  TodoNotifier(this._repo) : super(TodoState()) {
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
    try {
      final response = await _repo.createTodo(
        recipeNames: recipeNames,
        servings: servings,
        items: items,
      );
      await loadTodoLists();
      return response['data']?['todo_id'];
    } catch (_) {
      return null;
    }
  }

  Future<List<TodoItem>?> loadTodoDetail(String todoId) async {
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
    await _repo.toggleTodoItem(itemId, isPurchased: isPurchased);
    await loadTodoDetail(todoId);
    await loadTodoLists();
  }

  Future<void> deleteTodo(String todoId) async {
    await _repo.deleteTodo(todoId);
    await loadTodoLists();
  }

  Future<void> updateStatus(String todoId, String status) async {
    await _repo.updateTodoStatus(todoId, status);
    await loadTodoLists();
  }
}

final todoProvider = StateNotifierProvider<TodoNotifier, TodoState>(
  (ref) => TodoNotifier(TodoRepository(apiClient: ref.watch(apiClientProvider))),
);
