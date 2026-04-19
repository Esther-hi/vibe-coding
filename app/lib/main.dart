import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/local/local_storage.dart';
import 'presentation/providers/api_client_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localStorage = LocalStorage();
  await localStorage.init();
  runApp(ProviderScope(
    overrides: [localStorageProvider.overrideWithValue(localStorage)],
    child: const KitchenAssistantApp(),
  ));
}

class KitchenAssistantApp extends StatelessWidget {
  const KitchenAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '智能厨房助手',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
    );
  }
}
