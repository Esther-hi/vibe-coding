import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/recipe_provider.dart';
import '../../providers/ingredient_provider.dart';
import '../../providers/shopping_list_provider.dart';

class CookingScreen extends ConsumerStatefulWidget {
  const CookingScreen({super.key});

  @override
  ConsumerState<CookingScreen> createState() => _CookingScreenState();
}

class _CookingScreenState extends ConsumerState<CookingScreen> {
  int _currentStep = 0;

  void _showCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('确认完成本次烹饪？'),
        content: const Text('确认后进入"开始品鉴"，并返回首页，结束本次做饭流程。'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _finishCooking();
            },
            child: const Text('确认完成（开始品鉴）'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/');
            },
            child: const Text('返回首页'),
          ),
        ],
      ),
    );
  }

  void _finishCooking() {
    // 清理所有状态，回到首页开始新的流程
    ref.read(ingredientProvider.notifier).clear();
    ref.read(recipeProvider.notifier).clear();
    ref.read(shoppingListProvider.notifier).clear();
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final recipe = ref.watch(recipeProvider).selectedRecipe;

    if (recipe == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('开始做饭')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('未选择菜谱', style: TextStyle(color: Colors.grey[600])),
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

    final steps = recipe.steps;
    final servings = recipe.servings ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('开始做饭')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 当前菜品卡片
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('当前菜品', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(recipe.name, style: const TextStyle(fontSize: 15)),
                      Text(servings, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
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
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('制作步骤', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Divider(height: 16),
                  ...steps.asMap().entries.map((entry) {
                    final index = entry.key;
                    final step = entry.value;
                    final isCurrent = index == _currentStep;
                    final isDone = index < _currentStep;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _currentStep = index),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? Theme.of(context).colorScheme.primaryContainer
                                : isDone
                                    ? Colors.grey[100]
                                    : null,
                            borderRadius: BorderRadius.circular(14),
                            border: isCurrent
                                ? Border.all(color: Theme.of(context).colorScheme.primary)
                                : Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                isDone ? Icons.check_circle : isCurrent ? Icons.play_circle_filled : Icons.radio_button_unchecked,
                                size: 20,
                                color: isDone
                                    ? Colors.green
                                    : isCurrent
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey[400],
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '步骤 ${index + 1}',
                                      style: TextStyle(
                                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      step,
                                      style: TextStyle(
                                        fontSize: 13,
                                        decoration: isDone ? TextDecoration.lineThrough : null,
                                        color: isDone ? Colors.grey : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  // 下一步按钮
                  if (_currentStep < steps.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => setState(() => _currentStep++),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('完成烹饪',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
