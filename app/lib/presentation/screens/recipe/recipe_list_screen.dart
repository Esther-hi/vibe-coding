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
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('优先推荐匹配度高、缺料少、适合快速制作的菜。',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                const SizedBox(height: 16),
                ...state.recipes.map((recipe) => _buildRecipeCard(context, ref, state, recipe, theme)),
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
          ),
        ),
        if (state.selectedRecipeIds.isNotEmpty) _buildBottomBar(context, ref, state, theme),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, WidgetRef ref, RecipeState state, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '已选 ${state.selectedRecipeIds.length} 道菜 · 缺失食材将合并到购物清单',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (state.selectedRecipeIds.length == 1) {
                  final recipe = state.recipes.firstWhere((r) => r.id == state.selectedRecipeIds.first);
                  ref.read(recipeProvider.notifier).selectRecipe(recipe);
                  context.push('/recipes/${recipe.id}');
                } else {
                  final firstRecipe = state.recipes.firstWhere((r) => state.selectedRecipeIds.contains(r.id));
                  ref.read(recipeProvider.notifier).selectRecipe(firstRecipe);
                  context.push('/recipes/${firstRecipe.id}');
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('查看详情并生成购物清单', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, WidgetRef ref, RecipeState state, Recipe recipe, ThemeData theme) {
    final missingCount = recipe.missingIngredients.length;
    final isSelected = state.selectedRecipeIds.contains(recipe.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: () {
          ref.read(recipeProvider.notifier).toggleRecipeSelection(recipe.id);
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? theme.colorScheme.primary : Colors.grey,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(recipe.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 34),
                child: Text(
                  '${recipe.servings ?? "${recipe.cookingTime}分钟"} · ${recipe.cookingTime}分钟 · ${recipe.difficulty} · 缺$missingCount项',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
