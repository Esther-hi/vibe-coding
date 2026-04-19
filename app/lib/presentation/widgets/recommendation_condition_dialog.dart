import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/recipe_provider.dart';

class RecommendationConditionDialog extends ConsumerStatefulWidget {
  final List<String> ingredients;

  const RecommendationConditionDialog({super.key, required this.ingredients});

  @override
  ConsumerState<RecommendationConditionDialog> createState() => _RecommendationConditionDialogState();
}

class _RecommendationConditionDialogState extends ConsumerState<RecommendationConditionDialog> {
  int _peopleCount = 2;
  String? _tastePreference;
  String? _cookingTimeLimit;
  bool _isGenerating = false;

  static const _peopleOptions = [1, 2, 3, 4];
  static const _peopleLabels = ['1人', '2人', '3-4人', '5人+'];
  static const _tasteOptions = ['清淡', '下饭', '不辣', '微辣'];
  static const _timeOptions = ['15分钟内', '30分钟内', '不限'];

  Future<void> _generate() async {
    setState(() => _isGenerating = true);

    ref.read(recipeProvider.notifier).setPeopleCount(_peopleCount);
    ref.read(recipeProvider.notifier).setTastePreference(_tastePreference);
    ref.read(recipeProvider.notifier).setCookingTimeLimit(
      _cookingTimeLimit == '不限' ? null : _cookingTimeLimit,
    );

    await ref.read(recipeProvider.notifier).generateRecipes(widget.ingredients);

    if (mounted) {
      final state = ref.read(recipeProvider);
      if (state.error == null) {
        // go() 替换整个 GoRouter 栈，直接到推荐列表页
        context.go('/recipes');
      } else {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error!)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('推荐条件')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('人数必填，口味和时长可选。先收最少信息，再给更合理的推荐。',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 16),

            // 用餐人数
            _buildSection(
              title: '几个人吃饭？',
              child: Wrap(
                spacing: 8,
                children: List.generate(_peopleOptions.length, (i) {
                  final selected = _peopleCount == _peopleOptions[i];
                  return ChoiceChip(
                    label: Text(_peopleLabels[i]),
                    selected: selected,
                    onSelected: (_) => setState(() => _peopleCount = _peopleOptions[i]),
                  );
                }),
              ),
            ),

            const SizedBox(height: 16),

            // 口味偏好
            _buildSection(
              title: '口味偏好（可选）',
              child: Wrap(
                spacing: 8,
                children: _tasteOptions.map((taste) {
                  final selected = _tastePreference == taste;
                  return ChoiceChip(
                    label: Text(taste),
                    selected: selected,
                    onSelected: (sel) {
                      setState(() => _tastePreference = sel ? taste : null);
                    },
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // 烹饪时长
            _buildSection(
              title: '烹饪时长（可选）',
              child: Wrap(
                spacing: 8,
                children: _timeOptions.map((time) {
                  final selected = _cookingTimeLimit == time;
                  return ChoiceChip(
                    label: Text(time),
                    selected: selected,
                    onSelected: (sel) {
                      setState(() => _cookingTimeLimit = sel ? time : null);
                    },
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 32),

            // 生成推荐按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isGenerating ? null : _generate,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isGenerating
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('生成推荐', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// Helper function to navigate to the condition page via GoRouter
void showRecommendationConditionDialog(
  BuildContext context,
  WidgetRef ref,
  List<String> ingredients,
) {
  context.push('/recommendation-conditions', extra: ingredients);
}
