import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/ingredient_provider.dart';
import '../../widgets/recommendation_condition_dialog.dart';

class IngredientConfirmScreen extends ConsumerStatefulWidget {
  const IngredientConfirmScreen({super.key});

  @override
  ConsumerState<IngredientConfirmScreen> createState() => _IngredientConfirmScreenState();
}

class _IngredientConfirmScreenState extends ConsumerState<IngredientConfirmScreen> {
  final _addController = TextEditingController();

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  void _removeIngredient(int index) {
    ref.read(ingredientProvider.notifier).removeIngredient(index);
  }

  void _editIngredient(int index, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑食材'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(ingredientProvider.notifier).editIngredient(index, controller.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _addIngredient() {
    final text = _addController.text.trim();
    if (text.isNotEmpty) {
      ref.read(ingredientProvider.notifier).addManualIngredient(text);
      _addController.clear();
    }
  }

  void _showRecommendationDialog() {
    final ingredients = ref.read(ingredientProvider).ingredients;
    if (ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少添加一种食材')),
      );
      return;
    }
    showRecommendationConditionDialog(context, ref, ingredients);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ingredientProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('确认食材')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('请确认哪些食材识别正确，也可以补充遗漏项。',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 16),

            // 食材列表
            ...state.ingredients.asMap().entries.map((entry) => _buildIngredientItem(entry.key, entry.value)),

            if (state.ingredients.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text('暂无食材，请返回添加', style: TextStyle(color: Colors.grey[500])),
                ),
              ),

            const SizedBox(height: 16),

            // 补充食材区域
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(18),
                color: Colors.grey[50],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('补充食材', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _addController,
                          decoration: const InputDecoration(
                            hintText: '输入食材名称',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                          ),
                          onSubmitted: (_) => _addIngredient(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.outlined(
                        onPressed: _addIngredient,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 确认按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: state.ingredients.isEmpty ? null : _showRecommendationDialog,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('确认并开始推荐', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientItem(int index, String name) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(child: Text(name, style: const TextStyle(fontSize: 14))),
            TextButton(
              onPressed: () => _editIngredient(index, name),
              child: const Text('编辑', style: TextStyle(fontSize: 12)),
            ),
            TextButton(
              onPressed: () => _removeIngredient(index),
              child: Text('删除', style: TextStyle(fontSize: 12, color: Colors.red[300])),
            ),
          ],
        ),
      ),
    );
  }
}
