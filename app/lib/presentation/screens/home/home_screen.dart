import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('智能厨房助手'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题区
            Text('🍳 今晚吃什么？',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('基于你家里现有食材，快速推荐可做菜谱。',
                style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryTextColor)),
            const SizedBox(height: 20),

            // 主入口区
            SlideInAnimation(
              index: 0,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context).cardColor,
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: TapScale(
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/ingredients/input'),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('拍照 / 上传识别食材'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: TapScale(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/ingredients/input?mode=manual'),
                          icon: const Icon(Icons.edit),
                          label: const Text('手动输入食材'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: TapScale(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/shopping-list'),
                          icon: const Icon(Icons.shopping_cart_outlined),
                          label: const Text('查看购物清单'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: AppTheme.secondaryTextColor.withValues(alpha: 0.4), style: BorderStyle.solid),
                            ),
                            foregroundColor: AppTheme.secondaryTextColor,
                            textStyle: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 价值展示区
            SlideInAnimation(
              index: 2,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('✨ 产品主价值', style: TextStyle(fontWeight: FontWeight.bold)),
                    Divider(height: 20, color: AppTheme.primaryColor.withValues(alpha: 0.12)),
                    _buildValueItem(context, '🍽️', '知道能做什么', '推荐菜谱'),
                    const SizedBox(height: 8),
                    _buildValueItem(context, '📋', '知道怎么做', '步骤清晰'),
                    const SizedBox(height: 8),
                    _buildValueItem(context, '🛒', '知道还缺什么', '购物清单'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueItem(BuildContext context, String emoji, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 13)),
            ],
          ),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.secondaryTextColor)),
        ],
      ),
    );
  }
}
