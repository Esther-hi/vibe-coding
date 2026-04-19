import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/todo_provider.dart';

class TodoScreen extends ConsumerWidget {
  const TodoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todoState = ref.watch(todoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('待办')),
      body: todoState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : todoState.todoLists.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.checklist, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('暂无待办',
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[400])),
                      const SizedBox(height: 8),
                      Text('在购物清单中点击"加入待办"',
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey[400])),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(todoProvider.notifier).loadTodoLists(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: todoState.todoLists.length,
                    itemBuilder: (context, index) {
                      final todo = todoState.todoLists[index];
                      final statusText = todo.status == 'pending'
                          ? '待采购'
                          : todo.status == 'shopping'
                              ? '采购中'
                              : '已完成';
                      final statusColor = todo.status == 'pending'
                          ? Colors.orange
                          : todo.status == 'shopping'
                              ? Colors.blue
                              : Colors.green;

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
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(statusText,
                                        style: TextStyle(
                                            color: statusColor, fontSize: 12)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${todo.totalItems}项食材 · ${todo.pendingItems}项待购买',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 13),
                              ),
                              if (todo.servings != null)
                                Text('份量: ${todo.servings}',
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 13)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () async {
                                        await ref
                                            .read(todoProvider.notifier)
                                            .loadTodoDetail(todo.id);
                                        if (context.mounted) {
                                          context.push('/shopping-list');
                                        }
                                      },
                                      child: Text(todo.status == 'pending'
                                          ? '开始采购'
                                          : '继续采购'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red),
                                    onPressed: () async {
                                      final confirm =
                                          await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('确认删除'),
                                          content: Text(
                                              '确定删除"${todo.recipeNames.join("、")}"的待办吗？'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: const Text('取消'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, true),
                                              child: const Text('删除'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        ref
                                            .read(todoProvider.notifier)
                                            .deleteTodo(todo.id);
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
}
