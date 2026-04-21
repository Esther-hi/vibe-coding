import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/recipe_provider.dart';
import '../../providers/ingredient_provider.dart';
import '../../providers/shopping_list_provider.dart';
import '../../../data/models/recipe.dart';
import '../../widgets/timer_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animations.dart';

class CookingScreen extends ConsumerStatefulWidget {
  const CookingScreen({super.key});

  @override
  ConsumerState<CookingScreen> createState() => _CookingScreenState();
}

class _CookingScreenState extends ConsumerState<CookingScreen> {
  int _currentStep = 0;
  bool _showingCelebration = false;

  List<Recipe> get _recipes {
    final state = ref.read(recipeProvider);
    if (state.selectedRecipeIds.length > 1) {
      return state.recipes
          .where((r) => state.selectedRecipeIds.contains(r.id))
          .toList();
    }
    final recipe = state.selectedRecipe;
    return recipe != null ? [recipe] : [];
  }

  void _showCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🎉 烹饪完成！'),
        content: Text(_recipes.length > 1
            ? '${_recipes.map((r) => r.name).join("、")} 已全部完成，开始品鉴吧！'
            : '${_recipes.first.name} 已完成，开始品鉴吧！'),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _showingCelebration = true);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: const Text('开始品鉴', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _finishCooking() {
    ref.read(ingredientProvider.notifier).clear();
    ref.read(recipeProvider.notifier).clear();
    ref.read(shoppingListProvider.notifier).clear();
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recipeProvider);
    final recipes = _recipes;

    // 庆祝动画页面（不用 showDialog，避免 barrier 残留）
    if (_showingCelebration) {
      return Scaffold(
        backgroundColor: Colors.black26,
        body: CelebrationOverlay(
          onComplete: _finishCooking,
        ),
      );
    }

    if (state.selectedRecipe == null || recipes.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('👨‍🍳 开始做饭')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('未选择菜谱', style: TextStyle(color: AppTheme.secondaryTextColor)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('返回首页'),
              ),
            ],
          ),
        ),
      );
    }

    // 构建所有菜谱的合并步骤列表
    // 每个步骤记录它属于哪道菜
    final allSteps = <({Recipe recipe, int stepIndex, String text})>[];
    for (final recipe in recipes) {
      for (var i = 0; i < recipe.steps.length; i++) {
        allSteps.add((recipe: recipe, stepIndex: i, text: recipe.steps[i]));
      }
    }

    // 计算当前步骤所在的菜谱
    int stepOffset = 0;
    Recipe currentRecipeForStep = recipes.first;
    for (final recipe in recipes) {
      if (_currentStep < stepOffset + recipe.steps.length) {
        currentRecipeForStep = recipe;
        break;
      }
      stepOffset += recipe.steps.length;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('👨‍🍳 开始做饭')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 当前菜品卡片
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.15)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipes.length > 1 ? '🍜 当前菜品 (${_currentStep + 1}/${allSteps.length})' : '🍜 当前菜品',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Divider(height: 16, color: AppTheme.primaryColor.withValues(alpha: 0.15)),
                  if (recipes.length > 1)
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: recipes.asMap().entries.map((entry) {
                        final isActive = entry.value.id == currentRecipeForStep.id;
                        return Chip(
                          label: Text(entry.value.name),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: isActive
                              ? AppTheme.primaryColor.withValues(alpha: 0.15)
                              : null,
                          side: isActive
                              ? BorderSide(color: AppTheme.primaryColor)
                              : null,
                        );
                      }).toList(),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(recipes.first.name, style: const TextStyle(fontSize: 15)),
                        Text(recipes.first.servings ?? '', style: TextStyle(color: AppTheme.secondaryTextColor, fontSize: 12)),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 制作步骤
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.15)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📝 制作步骤', style: TextStyle(fontWeight: FontWeight.bold)),
                  Divider(height: 16, color: AppTheme.primaryColor.withValues(alpha: 0.15)),
                  ...allSteps.asMap().entries.map((entry) {
                    final globalIndex = entry.key;
                    final step = entry.value;
                    final stepInfo = StepInfo.parse(step.text);
                    final isCurrent = globalIndex == _currentStep;
                    final isDone = globalIndex < _currentStep;

                    // 判断是否是菜谱分界线
                    final showRecipeLabel = _isFirstStepOfRecipe(globalIndex, recipes);

                    return SlideInAnimation(
                      index: globalIndex,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showRecipeLabel && recipes.length > 1) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '🍽️ ${step.recipe.name}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _currentStep = globalIndex),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? AppTheme.primaryColor.withValues(alpha: 0.08)
                                      : isDone
                                          ? AppTheme.successColor.withValues(alpha: 0.08)
                                          : null,
                                  borderRadius: BorderRadius.circular(14),
                                  border: isCurrent
                                      ? Border.all(color: AppTheme.primaryColor)
                                      : Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.12)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      isDone ? Icons.check_circle : isCurrent ? Icons.play_circle_filled : Icons.radio_button_unchecked,
                                      size: 20,
                                      color: isDone
                                          ? AppTheme.successColor
                                          : isCurrent
                                              ? AppTheme.primaryColor
                                              : AppTheme.secondaryTextColor,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '步骤 ${step.stepIndex + 1}',
                                            style: TextStyle(
                                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                              fontSize: 12,
                                              color: AppTheme.secondaryTextColor,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            stepInfo.text,
                                            style: TextStyle(
                                              fontSize: 13,
                                              decoration: isDone ? TextDecoration.lineThrough : null,
                                              color: isDone ? AppTheme.secondaryTextColor : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (stepInfo.timerMinutes != null)
                                      IconButton(
                                        icon: const Icon(Icons.timer, size: 20),
                                        color: AppTheme.primaryColor,
                                        onPressed: () {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            builder: (_) => TimerWidget(
                                              minutes: stepInfo.timerMinutes!,
                                              stepDescription: stepInfo.text,
                                              onComplete: () {
                                                Navigator.pop(context);
                                                showDialog(
                                                  context: context,
                                                  builder: (dialogCtx) => AlertDialog(
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                                    title: const Text('⏰ 这一步完成啦！'),
                                                    content: Text(stepInfo.text),
                                                    actions: [TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('好的'))],
                                                  ),
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // 下一步按钮
                  if (_currentStep < allSteps.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => setState(() => _currentStep++),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          child: const Text('下一步'),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 完成烹饪按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showCompleteDialog,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: const Text('🎉 完成烹饪',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isFirstStepOfRecipe(int globalIndex, List<Recipe> recipes) {
    int offset = 0;
    for (final recipe in recipes) {
      if (offset == globalIndex) return true;
      offset += recipe.steps.length;
      if (offset > globalIndex) return false;
    }
    return false;
  }
}
