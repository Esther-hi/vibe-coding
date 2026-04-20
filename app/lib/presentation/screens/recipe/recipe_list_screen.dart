import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/recipe_provider.dart';
import '../../providers/ingredient_provider.dart';
import '../../widgets/recommendation_condition_dialog.dart';
import '../../../data/models/recipe.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animations.dart';

class RecipeListScreen extends ConsumerWidget {
  const RecipeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recipeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('🍽️ 推荐菜谱')),
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
          const Text('🍽️', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text('请先识别食材', style: TextStyle(color: AppTheme.secondaryTextColor)),
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
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryTextColor)),
                const SizedBox(height: 16),
                ...state.recipes.asMap().entries.map((entry) => SlideInAnimation(
                      index: entry.key,
                      child: _buildRecipeCard(context, ref, state, entry.value, theme),
                    )),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    final ingredients = ref.read(ingredientProvider).ingredients;
                    showRecommendationConditionDialog(context, ref, ingredients);
                  },
                  icon: const Icon(Icons.tune, size: 16),
                  label: const Text('重新调整人数 / 口味 / 时长'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.2), style: BorderStyle.solid),
                    foregroundColor: AppTheme.secondaryTextColor,
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
        border: Border(top: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.12))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '已选 ${state.selectedRecipeIds.length} 道菜 · 缺失食材将合并到购物清单',
            style: const TextStyle(color: AppTheme.secondaryTextColor, fontSize: 13),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final recipe = state.recipes.cast<Recipe?>().firstWhere(
                  (r) => r != null && state.selectedRecipeIds.contains(r.id),
                  orElse: () => null,
                );
                if (recipe != null) {
                  ref.read(recipeProvider.notifier).selectRecipe(recipe);
                  context.push('/recipes/${recipe.id}');
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
                        color: isSelected ? theme.colorScheme.primary : AppTheme.secondaryTextColor,
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
                  '${recipe.servings ?? ""} · ${recipe.cookingTime}分钟 · ${recipe.difficulty} · 缺$missingCount项',
                  style: const TextStyle(color: AppTheme.secondaryTextColor, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
