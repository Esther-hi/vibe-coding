import 'package:go_router/go_router.dart';

import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/recipe/recipe_list_screen.dart';
import '../../presentation/screens/recipe/recipe_detail_screen.dart';
import '../../presentation/screens/favorites/favorites_screen.dart';
import '../../presentation/screens/shopping_list/shopping_list_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/ingredients/ingredient_input_screen.dart';
import '../../presentation/screens/ingredients/ingredient_confirm_screen.dart';
import '../../presentation/screens/cooking/cooking_screen.dart';
import '../../presentation/widgets/recommendation_condition_dialog.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/ingredients/input',
        builder: (context, state) {
          final isManual = state.uri.queryParameters['mode'] == 'manual';
          return IngredientInputScreen(isManual: isManual);
        },
      ),
      GoRoute(
        path: '/ingredients/confirm',
        builder: (context, state) => const IngredientConfirmScreen(),
      ),
      GoRoute(
        path: '/recommendation-conditions',
        builder: (context, state) {
          final ingredients = state.extra as List<String>? ?? [];
          return RecommendationConditionDialog(ingredients: ingredients);
        },
      ),
      GoRoute(
        path: '/recipes',
        builder: (context, state) => const RecipeListScreen(),
      ),
      GoRoute(
        path: '/recipes/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return RecipeDetailScreen(recipeId: id);
        },
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/shopping-list',
        builder: (context, state) => const ShoppingListScreen(),
      ),
      GoRoute(
        path: '/cooking',
        builder: (context, state) => const CookingScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
}
