class RecipeIngredient {
  final String name;
  final String quantity;
  final bool isAvailable;

  RecipeIngredient({
    required this.name,
    required this.quantity,
    this.isAvailable = true,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? '',
      isAvailable: json['is_available'] ?? true,
    );
  }
}

class Nutrition {
  final String calories;
  final String protein;
  final String carbs;
  final String fat;

  Nutrition({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory Nutrition.fromJson(Map<String, dynamic> json) {
    return Nutrition(
      calories: json['calories'] ?? '',
      protein: json['protein'] ?? '',
      carbs: json['carbs'] ?? '',
      fat: json['fat'] ?? '',
    );
  }
}

class Recipe {
  final String id;
  final String name;
  final String difficulty;
  final int cookingTime;
  final String cuisine;
  final String? servings;
  final List<RecipeIngredient> ingredients;
  final List<RecipeIngredient> missingIngredients;
  final List<String> steps;
  final Nutrition nutrition;
  final String? tips;

  Recipe({
    required this.id,
    required this.name,
    required this.difficulty,
    required this.cookingTime,
    required this.cuisine,
    this.servings,
    required this.ingredients,
    required this.missingIngredients,
    required this.steps,
    required this.nutrition,
    this.tips,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    // missing_ingredients can be List<String> (old format) or List<Map> (new format)
    List<RecipeIngredient> parseMissingIngredients(dynamic raw) {
      if (raw is List) {
        return raw.map((e) {
          if (e is Map<String, dynamic>) {
            return RecipeIngredient.fromJson(e);
          }
          return RecipeIngredient(name: e.toString(), quantity: '', isAvailable: false);
        }).toList();
      }
      return [];
    }

    return Recipe(
      id: json['recipe_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      difficulty: json['difficulty'] ?? '简单',
      cookingTime: json['cooking_time'] ?? 0,
      cuisine: json['cuisine'] ?? '',
      servings: json['servings'],
      ingredients: (json['ingredients'] as List?)
          ?.map((e) => RecipeIngredient.fromJson(e))
          .toList() ?? [],
      missingIngredients: parseMissingIngredients(json['missing_ingredients']),
      steps: List<String>.from(json['steps'] ?? []),
      nutrition: Nutrition.fromJson(json['nutrition'] ?? {}),
      tips: json['tips'],
    );
  }
}
