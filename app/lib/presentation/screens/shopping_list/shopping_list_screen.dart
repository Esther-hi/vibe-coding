import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/shopping_list_provider.dart';
import '../../providers/todo_provider.dart';

class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  bool _isShopping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(shoppingListProvider);
      if (state.items.isEmpty && state.currentRecipeName == null) {
        ref.read(shoppingListProvider.notifier).loadShoppingList();
      }
    });
  }

  void _addToTodo() {
    final shoppingState = ref.read(shoppingListProvider);
    final items = shoppingState.items;
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('购物清单为空')),
      );
      return;
    }

    final recipeName = shoppingState.currentRecipeName ?? '菜谱';
    final servings = shoppingState.currentServings ?? '2人份';

    // 后台尝试保存到后端（不阻塞UI）
    final todoItems = items.map((item) => <String, dynamic>{
      'name': item.ingredientName,
      'quantity': item.quantity,
    }).toList();
    ref.read(todoProvider.notifier).createTodo([recipeName], servings, todoItems);

    // 立即返回首页
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$recipeName 已加入待办')),
    );
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shoppingListProvider);

    final unpurchased = state.items.where((e) => !e.isPurchased).toList();
    final purchased = state.items.where((e) => e.isPurchased).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('🛒 购物清单')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.items.isEmpty
              ? _buildEmptyState(context)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 当前菜谱信息
                      if (state.currentRecipeName != null)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: AppTheme.primaryColor.withValues(alpha: 0.15)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${state.currentRecipeName} · ${state.currentServings ?? ""}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Divider(
                                height: 16,
                                color: AppTheme.primaryColor.withValues(alpha: 0.12),
                              ),
                              ...unpurchased.map((item) => _buildItemRow(
                                context: context,
                                name: item.ingredientName,
                                detail: item.quantity,
                                isPurchased: false,
                                interactive: _isShopping,
                                onCheck: _isShopping ? () => ref.read(shoppingListProvider.notifier)
                                    .togglePurchased(item.id, true) : null,
                                onDelete: _isShopping ? () => ref.read(shoppingListProvider.notifier)
                                    .deleteItem(item.id) : null,
                              )),
                            ],
                          ),
                        ),

                      // 已购买区域
                      if (purchased.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            border: Border.all(
                                color: AppTheme.primaryColor.withValues(alpha: 0.1)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('已购买', style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.secondaryTextColor,
                              )),
                              Divider(
                                height: 16,
                                color: AppTheme.warmColor.withValues(alpha: 0.3),
                              ),
                              ...purchased.map((item) => _buildItemRow(
                                context: context,
                                name: item.ingredientName,
                                detail: '已购买',
                                isPurchased: true,
                                interactive: _isShopping,
                                onCheck: _isShopping ? () => ref.read(shoppingListProvider.notifier)
                                    .togglePurchased(item.id, false) : null,
                                onDelete: _isShopping ? () => ref.read(shoppingListProvider.notifier)
                                    .deleteItem(item.id) : null,
                              )),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // 有未购买项时：显示双按钮
                      if (unpurchased.isNotEmpty)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _addToTodo,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                ),
                                child: const Text('📋 加入待办',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() => _isShopping = true);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('开始采购，请逐项勾选已购买的食材')),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                ),
                                child: const Text('🛒 开始采购',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),

                      // 全部已购买时：显示完成按钮
                      if (unpurchased.isEmpty && purchased.isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => context.push('/cooking'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            child: const Text('👨‍🍳 完成采购，开始做饭',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🛒', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text('购物清单为空', style: TextStyle(color: AppTheme.secondaryTextColor)),
        ],
      ),
    );
  }

  Widget _buildItemRow({
    required BuildContext context,
    required String name,
    required String detail,
    required bool isPurchased,
    bool interactive = true,
    VoidCallback? onCheck,
    VoidCallback? onDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              isPurchased ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isPurchased ? AppTheme.successColor : AppTheme.secondaryTextColor,
              size: 20,
            ),
            onPressed: onCheck,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 13,
                decoration: isPurchased ? TextDecoration.lineThrough : null,
                color: isPurchased ? AppTheme.secondaryTextColor : null,
              ),
            ),
          ),
          Text(detail, style: TextStyle(color: AppTheme.secondaryTextColor, fontSize: 12)),
          const SizedBox(width: 4),
          if (!isPurchased && interactive)
            IconButton(
              icon: Icon(Icons.delete_outline,
                  size: 16, color: AppTheme.accentColor.withValues(alpha: 0.7)),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
