import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/recipe_provider.dart';
import '../../providers/shopping_list_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../../data/models/recipe.dart';
import '../../../core/theme/app_theme.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  final String recipeId;

  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  bool _isGeneratingShoppingList = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(recipeProvider);
      if (state.selectedRecipe == null || state.selectedRecipe!.id != widget.recipeId) {
        ref.read(recipeProvider.notifier).loadRecipeDetail(widget.recipeId);
      }
    });
  }

  List<Recipe> get _selectedRecipes {
    final state = ref.read(recipeProvider);
    if (state.selectedRecipeIds.length > 1) {
      return state.recipes
          .where((r) => state.selectedRecipeIds.contains(r.id))
          .toList();
    }
    final recipe = state.selectedRecipe;
    return recipe != null ? [recipe] : [];
  }

  bool get _allIngredientsAvailable {
    return _selectedRecipes.every((r) => r.missingIngredients.isEmpty);
  }

  Future<void> _generateShoppingList() async {
    final recipes = _selectedRecipes;
    if (recipes.isEmpty) return;

    setState(() => _isGeneratingShoppingList = true);
    if (recipes.length == 1) {
      await ref.read(shoppingListProvider.notifier).generateFromRecipe(recipes.first);
    } else {
      await ref.read(shoppingListProvider.notifier).generateFromRecipes(recipes);
    }
    setState(() => _isGeneratingShoppingList = false);

    if (mounted) {
      final shopState = ref.read(shoppingListProvider);
      if (shopState.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(shopState.error!)),
        );
      } else {
        context.push('/shopping-list');
      }
    }
  }

  void _goToCooking() {
    final state = ref.read(recipeProvider);
    if (state.selectedRecipe != null) {
      context.push('/cooking');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recipeProvider);
    final theme = Theme.of(context);
    final recipe = state.selectedRecipe;

    if (state.isLoading || recipe == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('菜谱详情')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final recipes = _selectedRecipes;
    final favNotifier = ref.read(favoritesProvider.notifier);
    final isFav = ref.watch(favoritesProvider).favorites.any((r) => r.id == recipe.id);

    return Scaffold(
      appBar: AppBar(
        title: recipes.length > 1
            ? Text('已选 ${recipes.length} 道菜')
            : Text(recipe.name),
        actions: [
          IconButton(
            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? Colors.red : null),
            onPressed: () => favNotifier.toggleFavorite(recipe.id),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 多选菜谱 Chip 列表
            if (recipes.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: recipes.map((r) => Chip(
                    label: Text(r.name),
                    visualDensity: VisualDensity.compact,
                  )).toList(),
                ),
              ),

            // 每道菜的详情
            ...recipes.map((r) => _buildRecipeCard(context, theme, r, favNotifier)),

            const SizedBox(height: 24),

            // 底部按钮
            _buildBottomButton(recipes),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, ThemeData theme, Recipe recipe, dynamic favNotifier) {
    final availableIngredients = recipe.ingredients.where((e) => e.isAvailable).toList();
    final isFav = ref.watch(favoritesProvider).favorites.any((r) => r.id == recipe.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 菜名标题行
          Row(
            children: [
              Expanded(
                child: Text(recipe.name,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
              if (_selectedRecipes.length > 1)
                IconButton(
                  icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? Colors.red : null, size: 22),
                  onPressed: () => favNotifier.toggleFavorite(recipe.id),
                ),
            ],
          ),
          Text(
            '${recipe.servings ?? ""} ${recipe.cookingTime}分钟 · ${recipe.difficulty}',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryTextColor),
          ),
          const SizedBox(height: 12),

          // 已有食材
          if (availableIngredients.isNotEmpty)
            _buildSection(
              context: context,
              title: '✅ 已有食材',
              backgroundColor: AppTheme.successColor.withValues(alpha: 0.08),
              borderColor: AppTheme.successColor.withValues(alpha: 0.2),
              children: availableIngredients.map((ing) => _buildIngredientRow(
                '${ing.name} ${ing.quantity}', '已具备', AppTheme.successColor,
              )).toList(),
            ),

          if (availableIngredients.isNotEmpty && recipe.missingIngredients.isNotEmpty)
            const SizedBox(height: 12),

          // 缺失食材
          if (recipe.missingIngredients.isNotEmpty)
            _buildSection(
              context: context,
              title: '🛒 缺失食材',
              borderColor: AppTheme.warmColor.withValues(alpha: 0.2),
              backgroundColor: AppTheme.warmColor.withValues(alpha: 0.08),
              children: recipe.missingIngredients.map((ing) => _buildIngredientRow(
                '${ing.name} ${ing.quantity}', '待购买', AppTheme.warmColor,
              )).toList(),
            ),

          const SizedBox(height: 12),

          // 步骤
          _buildSection(
            context: context,
            title: '👨‍🍳 步骤',
            backgroundColor: Theme.of(context).cardColor,
            borderColor: AppTheme.primaryColor.withValues(alpha: 0.15),
            children: recipe.steps.asMap().entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('${entry.key + 1}. ${entry.value}',
                  style: TextStyle(color: AppTheme.textColor.withValues(alpha: 0.7), fontSize: 13)),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(List<Recipe> recipes) {
    if (_allIngredientsAvailable) {
      // 食材齐全 → 直接开始烹饪
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _goToCooking,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('食材齐全，开始烹饪',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      );
    }

    // 有缺失食材 → 生成购物清单
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isGeneratingShoppingList ? null : _generateShoppingList,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isGeneratingShoppingList
            ? const SizedBox(
                height: 20, width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Text('生成购物清单',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required Color? backgroundColor,
    required Color? borderColor,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor ?? Colors.grey),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Divider(height: 16, color: AppTheme.primaryColor.withValues(alpha: 0.12)),
          ...children,
        ],
      ),
    );
  }

  Widget _buildIngredientRow(String name, String badge, Color badgeColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontSize: 13)),
          Text(badge, style: TextStyle(fontSize: 12, color: badgeColor)),
        ],
      ),
    );
  }
}
