import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/shopping_list_provider.dart';

class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shoppingListProvider);

    final unpurchased = state.items.where((e) => !e.isPurchased).toList();
    final purchased = state.items.where((e) => e.isPurchased).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('购物清单')),
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
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${state.currentRecipeName} · ${state.currentServings ?? ""}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Divider(height: 16),
                              ...unpurchased.map((item) => _buildItemRow(
                                context: context,
                                name: item.ingredientName,
                                detail: item.quantity,
                                isPurchased: false,
                                onCheck: () => ref.read(shoppingListProvider.notifier)
                                    .togglePurchased(item.id, true),
                                onDelete: () => ref.read(shoppingListProvider.notifier)
                                    .deleteItem(item.id),
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
                            color: Colors.grey[50],
                            border: Border.all(color: Colors.grey[200]!),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('已购买', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                              const Divider(height: 16),
                              ...purchased.map((item) => _buildItemRow(
                                context: context,
                                name: item.ingredientName,
                                detail: '已购买',
                                isPurchased: true,
                                onCheck: () => ref.read(shoppingListProvider.notifier)
                                    .togglePurchased(item.id, false),
                                onDelete: () => ref.read(shoppingListProvider.notifier)
                                    .deleteItem(item.id),
                              )),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // 完成采购按钮
                      if (unpurchased.isEmpty && purchased.isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => context.push('/cooking'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('完成采购，开始做饭',
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
          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('购物清单为空', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildItemRow({
    required BuildContext context,
    required String name,
    required String detail,
    required bool isPurchased,
    required VoidCallback onCheck,
    required VoidCallback onDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              isPurchased ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isPurchased ? Colors.green : Colors.grey,
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
                color: isPurchased ? Colors.grey : null,
              ),
            ),
          ),
          Text(detail, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          const SizedBox(width: 4),
          if (!isPurchased)
            IconButton(
              icon: Icon(Icons.delete_outline, size: 16, color: Colors.red[300]),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
