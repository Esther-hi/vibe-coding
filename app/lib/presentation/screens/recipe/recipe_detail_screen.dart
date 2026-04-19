import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/recipe_provider.dart';
import '../../providers/shopping_list_provider.dart';
import '../../../data/models/recipe.dart';

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
    // If no recipe is selected in provider, load from backend
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(recipeProvider);
      if (state.selectedRecipe == null || state.selectedRecipe!.id != widget.recipeId) {
        ref.read(recipeProvider.notifier).loadRecipeDetail(widget.recipeId);
      }
    });
  }

  Future<void> _generateShoppingList(Recipe recipe) async {
    setState(() => _isGeneratingShoppingList = true);
    await ref.read(shoppingListProvider.notifier).generateFromRecipe(recipe);
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

    final availableIngredients = recipe.ingredients.where((e) => e.isAvailable).toList();

    return Scaffold(
      appBar: AppBar(title: Text(recipe.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题信息
            Text(recipe.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              '${recipe.servings ?? ""} ${recipe.cookingTime}分钟 · ${recipe.difficulty}',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            // 已有食材
            if (availableIngredients.isNotEmpty)
              _buildSection(
                context: context,
                title: '已有食材',
                backgroundColor: Colors.green[50],
                borderColor: Colors.green[100],
                children: availableIngredients.map((ing) => _buildIngredientRow(
                  '${ing.name} ${ing.quantity}', '已具备', Colors.green,
                )).toList(),
              ),

            const SizedBox(height: 12),

            // 缺失食材
            if (recipe.missingIngredients.isNotEmpty)
              _buildSection(
                context: context,
                title: '缺失食材',
                backgroundColor: Colors.orange[50],
                borderColor: Colors.orange[100],
                children: recipe.missingIngredients.map((ing) => _buildIngredientRow(
                  '${ing.name} ${ing.quantity}', '待购买', Colors.orange,
                )).toList(),
              ),

            const SizedBox(height: 12),

            // 步骤摘要
            _buildSection(
              context: context,
              title: '步骤',
              backgroundColor: Colors.white,
              borderColor: Colors.grey[300],
              children: recipe.steps.asMap().entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('${entry.key + 1}. ${entry.value}',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13)),
              )).toList(),
            ),

            const SizedBox(height: 24),

            // 生成购物清单按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: recipe.missingIngredients.isEmpty
                    ? null
                    : _isGeneratingShoppingList
                        ? null
                        : () => _generateShoppingList(recipe),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isGeneratingShoppingList
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        recipe.missingIngredients.isEmpty
                            ? '食材齐全，无需购物清单'
                            : '生成购物清单',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
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
          const Divider(height: 16),
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
