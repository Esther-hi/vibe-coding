import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('个人中心'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          // 用户头像和信息
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.green[100],
                  child: Icon(Icons.person, size: 50, color: Colors.green[700]),
                ),
                const SizedBox(height: 12),
                const Text('用户名', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Text('user@example.com', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // 设置项
          _buildSettingItem(Icons.restaurant, '口味偏好', '设置你的口味偏好'),
          _buildSettingItem(Icons.history, '识别历史', '查看食材识别历史'),
          _buildSettingItem(Icons.notifications, '通知设置', '管理推送通知'),
          _buildSettingItem(Icons.help, '帮助中心', '常见问题与反馈'),
          _buildSettingItem(Icons.info, '关于我们', '版本信息'),
          const SizedBox(height: 20),
          // 退出登录按钮
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton(
              onPressed: () {
                // TODO: 退出登录
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              child: const Text('退出登录'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // TODO: 跳转到对应页面
      },
    );
  }
}
