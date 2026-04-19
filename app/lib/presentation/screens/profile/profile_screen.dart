import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _maskPhone(String? phone) {
    if (phone == null || phone.length < 7) return '未绑定';
    return '${phone.substring(0, 3)}****${phone.substring(phone.length - 4)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        children: [
          // User info card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    (authState.username ?? '?')[0].toUpperCase(),
                    style: const TextStyle(fontSize: 28, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  authState.username ?? '未登录',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _maskPhone(authState.phone),
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),

          // Menu items
          _buildMenuItem(context, Icons.favorite, '收藏菜谱', () => context.push('/favorites')),
          _buildMenuItem(context, Icons.history, '识别历史', () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('识别历史功能开发中')));
          }),
          _buildMenuItem(context, Icons.tune, '口味偏好', () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('口味偏好功能开发中')));
          }),
          _buildMenuItem(context, Icons.notifications, '通知设置', () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('通知设置功能开发中')));
          }),
          _buildMenuItem(context, Icons.help, '帮助中心', () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('帮助中心功能开发中')));
          }),
          _buildMenuItem(context, Icons.info, '关于我们', () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('智能厨房助手 V1.0')));
          }),

          const SizedBox(height: 20),

          // Logout button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton(
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('退出登录', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
