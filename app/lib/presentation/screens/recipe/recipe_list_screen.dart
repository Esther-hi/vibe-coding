import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/recipe_provider.dart';
import '../../providers/ingredient_provider.dart';
import '../../widgets/recommendation_condition_dialog.dart';
import '../../../data/models/recipe.dart';

class RecipeListScreen extends ConsumerWidget {
  const RecipeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recipeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('推荐菜谱')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.recipes.isEmpty
              ? _buildEmptyState(context, theme)
              : _buildRecipeList(context, ref, state, theme),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('请先识别食材', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/ingredients/input'),
            child: const Text('去添加食材'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeList(BuildContext context, WidgetRef ref, RecipeState state, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('优先推荐匹配度高、缺料少、适合快速制作的菜。',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
          const SizedBox(height: 16),
          ...state.recipes.map((recipe) => _buildRecipeCard(context, ref, recipe)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              final ingredients = ref.read(ingredientProvider).ingredients;
              showRecommendationConditionDialog(context, ref, ingredients);
            },
            icon: const Icon(Icons.tune),
            label: const Text('重新调整人数 / 口味 / 时长'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              side: BorderSide(color: Colors.grey[300]!, style: BorderStyle.solid),
              foregroundColor: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, WidgetRef ref, Recipe recipe) {
    final missingCount = recipe.missingIngredients.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(recipe.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              '${recipe.servings ?? "${recipe.cookingTime}分钟"} · ${recipe.cookingTime}分钟 · ${recipe.difficulty} · 缺$missingCount项',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  ref.read(recipeProvider.notifier).selectRecipe(recipe);
                  context.push('/recipes/${recipe.id}');
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('查看详情'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
