import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/recipe.dart';
import '../../data/repositories/recipe_repository.dart';
import 'api_client_provider.dart';

class RecipeState {
  final List<Recipe> recipes;
  final Recipe? selectedRecipe;
  final Set<String> selectedRecipeIds;
  final int peopleCount;
  final String? tastePreference;
  final String? cookingTimeLimit;
  final bool isLoading;
  final String? error;

  RecipeState({
    this.recipes = const [],
    this.selectedRecipe,
    this.selectedRecipeIds = const {},
    this.peopleCount = 2,
    this.tastePreference,
    this.cookingTimeLimit,
    this.isLoading = false,
    this.error,
  });

  RecipeState copyWith({
    List<Recipe>? recipes,
    Recipe? selectedRecipe,
    Set<String>? selectedRecipeIds,
    int? peopleCount,
    String? tastePreference,
    String? cookingTimeLimit,
    bool? isLoading,
    String? error,
  }) {
    return RecipeState(
      recipes: recipes ?? this.recipes,
      selectedRecipe: selectedRecipe ?? this.selectedRecipe,
      selectedRecipeIds: selectedRecipeIds ?? this.selectedRecipeIds,
      peopleCount: peopleCount ?? this.peopleCount,
      tastePreference: tastePreference ?? this.tastePreference,
      cookingTimeLimit: cookingTimeLimit ?? this.cookingTimeLimit,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class RecipeNotifier extends StateNotifier<RecipeState> {
  final RecipeRepository _repository;

  RecipeNotifier(this._repository) : super(RecipeState());

  void setPeopleCount(int count) {
    state = state.copyWith(peopleCount: count);
  }

  void setTastePreference(String? taste) {
    state = state.copyWith(tastePreference: taste);
  }

  void setCookingTimeLimit(String? limit) {
    state = state.copyWith(cookingTimeLimit: limit);
  }

  Future<void> generateRecipes(List<String> ingredients) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final preferences = <String, dynamic>{};
      if (state.tastePreference != null) {
        preferences['taste'] = state.tastePreference;
      }
      if (state.cookingTimeLimit != null) {
        preferences['cooking_time'] = state.cookingTimeLimit;
      }

      final response = await _repository.generateRecipes(
        ingredients: ingredients,
        peopleCount: state.peopleCount,
        preferences: preferences.isEmpty ? null : preferences,
      );

      final recipesData = response['data']?['recipes'] as List? ?? [];
      final recipes = recipesData.map((e) => Recipe.fromJson(e)).toList();

      state = state.copyWith(
        recipes: recipes,
        isLoading: false,
        selectedRecipeIds: recipes.isNotEmpty ? {recipes.first.id} : <String>{},
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '菜谱推荐失败，请重试',
      );
    }
  }

  void toggleRecipeSelection(String recipeId) {
    final current = Set<String>.from(state.selectedRecipeIds);
    if (current.contains(recipeId)) {
      current.remove(recipeId);
    } else {
      current.add(recipeId);
    }
    state = state.copyWith(selectedRecipeIds: current);
  }

  void clearSelection() {
    state = state.copyWith(selectedRecipeIds: {});
  }

  void selectRecipe(Recipe recipe) {
    state = state.copyWith(selectedRecipe: recipe);
  }

  Future<void> loadRecipeDetail(String recipeId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.getRecipe(recipeId);
      final recipe = Recipe.fromJson(response['data']);
      state = state.copyWith(selectedRecipe: recipe, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '加载菜谱失败');
    }
  }

  void clear() {
    state = RecipeState();
  }
}

final recipeRepositoryProvider = Provider((ref) => RecipeRepository(apiClient: ref.watch(apiClientProvider)));
final recipeProvider = StateNotifierProvider<RecipeNotifier, RecipeState>(
  (ref) => RecipeNotifier(ref.watch(recipeRepositoryProvider)),
);
