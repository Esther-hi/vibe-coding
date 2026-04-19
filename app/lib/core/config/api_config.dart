class ApiConfig {
  static const String baseUrl = 'http://192.168.124.8:8000/api/v1';

  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String currentUser = '/auth/me';

  static const String recognizeIngredients = '/ingredients/recognize';
  static const String ingredientHistory = '/ingredients/history';

  static const String generateRecipes = '/recipes/generate';
  static const String searchRecipes = '/recipes/search';
  static const String getRecipe = '/recipes/{id}';
  static const String favoriteRecipe = '/recipes/{id}/favorite';
  static const String favorites = '/recipes/favorites';

  static const String generateShoppingList = '/shopping-list/generate';
  static const String shoppingList = '/shopping-list';

  static const String sendCode = '/auth/send-code';
  static const String resetPassword = '/auth/reset-password';
  static const String todoList = '/shopping-list/todo';
  static const String chat = '/chat';
}
