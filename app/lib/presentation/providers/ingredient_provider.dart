import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/ingredient.dart';
import '../../data/repositories/ingredient_repository.dart';
import 'api_client_provider.dart';

class IngredientState {
  final List<String> ingredients;
  final RecognitionResult? lastRecognition;
  final bool isLoading;
  final String? error;

  IngredientState({
    this.ingredients = const [],
    this.lastRecognition,
    this.isLoading = false,
    this.error,
  });

  IngredientState copyWith({
    List<String>? ingredients,
    RecognitionResult? lastRecognition,
    bool? isLoading,
    String? error,
  }) {
    return IngredientState(
      ingredients: ingredients ?? this.ingredients,
      lastRecognition: lastRecognition ?? this.lastRecognition,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class IngredientNotifier extends StateNotifier<IngredientState> {
  final IngredientRepository _repository;

  IngredientNotifier(this._repository) : super(IngredientState());

  Future<void> recognizeFromImage(XFile imageFile) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.recognizeIngredients(imageFile);
      final result = RecognitionResult.fromJson(response['data'] ?? response);
      final names = result.ingredients.map((e) => e.name).toList();
      state = state.copyWith(
        ingredients: names,
        lastRecognition: result,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '识别失败，请手动输入食材',
      );
    }
  }

  void addManualIngredient(String name) {
    if (name.trim().isEmpty) return;
    state = state.copyWith(
      ingredients: [...state.ingredients, name.trim()],
    );
  }

  void removeIngredient(int index) {
    final list = [...state.ingredients];
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      state = state.copyWith(ingredients: list);
    }
  }

  void editIngredient(int index, String newName) {
    final list = [...state.ingredients];
    if (index >= 0 && index < list.length) {
      list[index] = newName.trim();
      state = state.copyWith(ingredients: list);
    }
  }

  void clear() {
    state = IngredientState();
  }
}

final ingredientRepositoryProvider = Provider((ref) => IngredientRepository(apiClient: ref.watch(apiClientProvider)));
final ingredientProvider = StateNotifierProvider<IngredientNotifier, IngredientState>(
  (ref) => IngredientNotifier(ref.watch(ingredientRepositoryProvider)),
);
