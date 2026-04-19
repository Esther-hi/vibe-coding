import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/recipe_repository.dart';
import '../../data/models/recipe.dart';
import 'api_client_provider.dart';

class FavoritesState {
  final List<Recipe> favorites;
  final bool isLoading;
  final String? error;
  FavoritesState({this.favorites = const [], this.isLoading = false, this.error});
  FavoritesState copyWith({List<Recipe>? favorites, bool? isLoading, String? error}) =>
      FavoritesState(favorites: favorites ?? this.favorites, isLoading: isLoading ?? this.isLoading, error: error);
}

class FavoritesNotifier extends StateNotifier<FavoritesState> {
  final RecipeRepository _repo;
  final Set<String> _favoriteIds = {};
  FavoritesNotifier(this._repo) : super(FavoritesState()) { loadFavorites(); }

  Future<void> loadFavorites() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _repo.getFavorites();
      final List list = response['data'] ?? [];
      final recipes = list.map((e) => Recipe.fromJson(e)).toList();
      _favoriteIds.clear();
      _favoriteIds.addAll(recipes.map((r) => r.id));
      state = state.copyWith(favorites: recipes, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  bool isFavorite(String recipeId) => _favoriteIds.contains(recipeId);

  Future<void> toggleFavorite(String recipeId) async {
    if (_favoriteIds.contains(recipeId)) {
      await _repo.unfavoriteRecipe(recipeId);
      _favoriteIds.remove(recipeId);
    } else {
      await _repo.favoriteRecipe(recipeId);
      _favoriteIds.add(recipeId);
    }
    await loadFavorites();
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, FavoritesState>(
  (ref) => FavoritesNotifier(RecipeRepository(apiClient: ref.watch(apiClientProvider))),
);
