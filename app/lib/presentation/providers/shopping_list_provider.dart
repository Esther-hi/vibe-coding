import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/shopping_list_item.dart';
import '../../data/models/recipe.dart';
import '../../data/repositories/shopping_list_repository.dart';
import 'api_client_provider.dart';

class ShoppingListState {
  final List<ShoppingListItemModel> items;
  final String? currentRecipeName;
  final String? currentServings;
  final String? currentRecipeId;
  final bool isLoading;
  final String? error;

  ShoppingListState({
    this.items = const [],
    this.currentRecipeName,
    this.currentServings,
    this.currentRecipeId,
    this.isLoading = false,
    this.error,
  });

  ShoppingListState copyWith({
    List<ShoppingListItemModel>? items,
    String? currentRecipeName,
    String? currentServings,
    String? currentRecipeId,
    bool? isLoading,
    String? error,
  }) {
    return ShoppingListState(
      items: items ?? this.items,
      currentRecipeName: currentRecipeName ?? this.currentRecipeName,
      currentServings: currentServings ?? this.currentServings,
      currentRecipeId: currentRecipeId ?? this.currentRecipeId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ShoppingListNotifier extends StateNotifier<ShoppingListState> {
  final ShoppingListRepository _repository;

  ShoppingListNotifier(this._repository) : super(ShoppingListState());

  Future<void> generateFromRecipe(Recipe recipe) async {
    // 如果已经为同一个菜谱生成过，不重复生成
    if (state.currentRecipeId == recipe.id && state.items.isNotEmpty) {
      return;
    }

    state = state.copyWith(
      isLoading: true,
      error: null,
      currentRecipeName: recipe.name,
      currentServings: recipe.servings,
      currentRecipeId: recipe.id,
    );
    try {
      // 先清除后端所有旧的购物清单数据
      await _clearAllItems();

      final missingIngredients = recipe.missingIngredients
          .map((e) => {'name': e.name, 'quantity': e.quantity})
          .toList();
      final availableIngredients = recipe.ingredients
          .where((e) => e.isAvailable)
          .map((e) => e.name)
          .toList();

      await _repository.generateShoppingList(
        recipeName: recipe.name,
        missingIngredients: missingIngredients,
        availableIngredients: availableIngredients,
      );

      await loadShoppingList();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '生成购物清单失败');
    }
  }

  Future<void> _clearAllItems() async {
    try {
      final response = await _repository.getShoppingList();
      final data = response['data'] as List? ?? [];
      for (var item in data) {
        final id = item['id'];
        if (id != null) {
          await _repository.deleteItem(id);
        }
      }
    } catch (_) {
      // 忽略清除失败的错误
    }
  }

  Future<void> loadShoppingList() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _repository.getShoppingList();
      final data = response['data'] as List? ?? [];
      final items = data.map((e) => ShoppingListItemModel.fromJson(e)).toList();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '加载购物清单失败');
    }
  }

  Future<void> togglePurchased(String itemId, bool isPurchased) async {
    try {
      await _repository.updateItem(itemId, isPurchased: isPurchased);
      final items = state.items.map((e) {
        if (e.id == itemId) return e.copyWith(isPurchased: isPurchased);
        return e;
      }).toList();
      state = state.copyWith(items: items);
    } catch (e) {
      state = state.copyWith(error: '更新状态失败');
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      await _repository.deleteItem(itemId);
      final items = state.items.where((e) => e.id != itemId).toList();
      state = state.copyWith(items: items);
    } catch (e) {
      state = state.copyWith(error: '删除失败');
    }
  }

  void clear() {
    state = ShoppingListState();
  }
}

final shoppingListRepositoryProvider = Provider((ref) => ShoppingListRepository(apiClient: ref.watch(apiClientProvider)));
final shoppingListProvider = StateNotifierProvider<ShoppingListNotifier, ShoppingListState>(
  (ref) => ShoppingListNotifier(ref.watch(shoppingListRepositoryProvider)),
);
