import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/favorites_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favState = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('❤️ 收藏菜谱')),
      body: favState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : favState.favorites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text('❤️', style: TextStyle(fontSize: 64)),
                      SizedBox(height: 16),
                      Text('暂无收藏', style: TextStyle(fontSize: 16, color: AppTheme.secondaryTextColor)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: favState.favorites.length,
                  itemBuilder: (context, index) {
                    final recipe = favState.favorites[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(recipe.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${recipe.servings ?? ""} · ${recipe.cookingTime}分钟 · ${recipe.difficulty}', style: const TextStyle(color: AppTheme.secondaryTextColor)),
                        trailing: IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.red),
                          onPressed: () => ref.read(favoritesProvider.notifier).toggleFavorite(recipe.id),
                        ),
                        onTap: () => context.push('/recipes/${recipe.id}'),
                      ),
                    );
                  },
                ),
    );
  }
}
