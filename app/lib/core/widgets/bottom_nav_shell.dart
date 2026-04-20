import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class BottomNavShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const BottomNavShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/chat'),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.smart_toy, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: '🔍 搜索'),
          BottomNavigationBarItem(icon: Icon(Icons.checklist), label: '📝 待办'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '👤 我的'),
        ],
      ),
    );
  }
}
