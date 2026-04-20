import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/todo.dart';
import '../../providers/todo_provider.dart';
import '../../providers/recipe_provider.dart';

class TodoScreen extends ConsumerWidget {
  const TodoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todoState = ref.watch(todoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('📝 待办')),
      body: todoState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : todoState.todoLists.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('📝', style: TextStyle(fontSize: 64)),
                      SizedBox(height: 16),
                      Text('暂无待办',
                          style: TextStyle(fontSize: 16, color: AppTheme.secondaryTextColor)),
                      SizedBox(height: 8),
                      Text('在购物清单中点击"加入待办"',
                          style: TextStyle(fontSize: 13, color: AppTheme.secondaryTextColor)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(todoProvider.notifier).loadTodoLists(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: todoState.todoLists.length,
                    itemBuilder: (context, index) {
                      final todo = todoState.todoLists[index];
                      final isCompleted = todo.status == 'completed';
                      final statusText = todo.status == 'pending'
                          ? '待采购'
                          : todo.status == 'shopping'
                              ? '采购中'
                              : '已完成';
                      final statusColor = todo.status == 'pending'
                          ? AppTheme.warmColor
                          : todo.status == 'shopping'
                              ? AppTheme.primaryColor
                              : AppTheme.successColor;

                      final hasDetail = todoState.todoDetails.containsKey(todo.id);
                      final items = todoState.todoDetails[todo.id] ?? [];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      todo.recipeNames.join('、'),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 12)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${todo.totalItems}项食材 · ${todo.pendingItems}项待购买',
                                style: const TextStyle(color: AppTheme.secondaryTextColor, fontSize: 13),
                              ),
                              if (todo.servings != null)
                                Text('份量: ${todo.servings}',
                                    style: const TextStyle(color: AppTheme.secondaryTextColor, fontSize: 13)),

                              // 展开的食材列表
                              if (hasDetail && items.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Divider(color: AppTheme.primaryColor.withValues(alpha: 0.12)),
                                const SizedBox(height: 8),
                                ...items.map((item) => _buildItemRow(context, ref, todo.id, item)),
                                const SizedBox(height: 8),
                                if (items.every((i) => i.isPurchased))
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        ref.read(todoProvider.notifier).deleteTodo(todo.id);
                                        context.push('/cooking');
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                      ),
                                      child: const Text('👨‍🍳 全部采购完成，开始做饭'),
                                    ),
                                  ),
                              ],

                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  if (!isCompleted)
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () async {
                                          // 展开食材列表进行勾选
                                          if (!hasDetail) {
                                            await ref.read(todoProvider.notifier).loadTodoDetail(todo.id);
                                            ref.read(todoProvider.notifier).updateStatus(todo.id, 'shopping');
                                          }
                                        },
                                        child: Text(hasDetail ? '采购中...' : '开始采购'),
                                      ),
                                    ),
                                  if (!isCompleted) const SizedBox(width: 12),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppTheme.accentColor),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          title: const Text('确认删除'),
                                          content: Text('确定删除"${todo.recipeNames.join("、")}"的待办吗？'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, false),
                                              child: const Text('取消'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, true),
                                              child: const Text('删除', style: TextStyle(color: AppTheme.accentColor)),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        ref.read(todoProvider.notifier).deleteTodo(todo.id);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildItemRow(BuildContext context, WidgetRef ref, String todoId, TodoItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () => ref.read(todoProvider.notifier).toggleItem(todoId, item.id, !item.isPurchased),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            children: [
              Icon(
                item.isPurchased ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 20,
                color: item.isPurchased ? AppTheme.successColor : AppTheme.secondaryTextColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.ingredientName,
                  style: TextStyle(
                    fontSize: 14,
                    decoration: item.isPurchased ? TextDecoration.lineThrough : null,
                    color: item.isPurchased ? AppTheme.secondaryTextColor : null,
                  ),
                ),
              ),
              Text(item.quantity,
                  style: const TextStyle(color: AppTheme.secondaryTextColor, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
