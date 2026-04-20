import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/ingredient_provider.dart';
import '../../../core/theme/app_theme.dart';

class IngredientInputScreen extends ConsumerStatefulWidget {
  final bool isManual;

  const IngredientInputScreen({super.key, this.isManual = false});

  @override
  ConsumerState<IngredientInputScreen> createState() => _IngredientInputScreenState();
}

class _IngredientInputScreenState extends ConsumerState<IngredientInputScreen> {
  int _modeIndex = 0; // 0: 拍照, 1: 上传, 2: 手动输入
  final _manualController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.isManual) _modeIndex = 2;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(source: source, maxWidth: 1024);
      if (image != null) {
        ref.read(ingredientProvider.notifier).recognizeFromImage(image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('选择图片失败，请手动输入食材')),
        );
      }
    }
  }

  void _addManualIngredient() {
    final text = _manualController.text.trim();
    if (text.isNotEmpty) {
      ref.read(ingredientProvider.notifier).addManualIngredient(text);
      _manualController.clear();
    }
  }

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ingredientProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('🥕 添加食材')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('支持拍照识别，也支持手动连续添加，避免识别失败直接卡住。',
                style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryTextColor)),
            const SizedBox(height: 16),

            // 模式切换
            Row(
              children: [
                _buildModeChip('拍照', 0, Icons.camera_alt),
                const SizedBox(width: 8),
                _buildModeChip('上传图片', 1, Icons.photo_library),
                const SizedBox(width: 8),
                _buildModeChip('手动输入', 2, Icons.edit),
              ],
            ),
            const SizedBox(height: 16),

            // 输入区域
            if (_modeIndex < 2)
              _buildImageArea(context, state),
            if (_modeIndex == 2)
              _buildManualInput(),

            const SizedBox(height: 16),

            // 已添加食材列表
            if (state.ingredients.isNotEmpty) ...[
              Text('✅ 已添加食材', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              ...state.ingredients.asMap().entries.map((entry) => _buildIngredientChip(entry.key, entry.value)),
            ],

            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),

            if (state.error != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(state.error!, style: TextStyle(color: AppTheme.warmColor)),
              ),

            const SizedBox(height: 16),

            // 继续按钮
            if (state.ingredients.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/ingredients/confirm'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text('➡️ 继续', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeChip(String label, int index, IconData icon) {
    final isActive = _modeIndex == index;
    return ChoiceChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      selected: isActive,
      onSelected: (_) => setState(() => _modeIndex = index),
    );
  }

  Widget _buildImageArea(BuildContext context, IngredientState state) {
    return GestureDetector(
      onTap: () => _pickImage(_modeIndex == 0 ? ImageSource.camera : ImageSource.gallery),
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.15), style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).cardColor,
        ),
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📷', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 8),
                  Text(_modeIndex == 0 ? '点击拍照' : '点击上传图片',
                      style: TextStyle(color: AppTheme.secondaryTextColor)),
                ],
              ),
      ),
    );
  }

  Widget _buildManualInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _manualController,
            decoration: const InputDecoration(
              hintText: '输入食材名称',
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
            onSubmitted: (_) => _addManualIngredient(),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _addManualIngredient,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('添加'),
        ),
      ],
    );
  }

  Widget _buildIngredientChip(int index, String name) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(child: Text(name, style: const TextStyle(fontSize: 14))),
            Text('已添加', style: TextStyle(color: AppTheme.successColor, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
