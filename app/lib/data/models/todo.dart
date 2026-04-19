class TodoItem {
  final String id;
  final String ingredientName;
  final String quantity;
  final bool isPurchased;

  TodoItem({
    required this.id,
    required this.ingredientName,
    required this.quantity,
    this.isPurchased = false,
  });

  factory TodoItem.fromJson(Map<String, dynamic> json) => TodoItem(
        id: json['id'],
        ingredientName: json['ingredient_name'],
        quantity: json['quantity'],
        isPurchased: json['is_purchased'] ?? false,
      );

  TodoItem copyWith({bool? isPurchased}) => TodoItem(
        id: id,
        ingredientName: ingredientName,
        quantity: quantity,
        isPurchased: isPurchased ?? this.isPurchased,
      );
}

class TodoListModel {
  final String id;
  final List<String> recipeNames;
  final String? servings;
  final String status;
  final int totalItems;
  final int pendingItems;

  TodoListModel({
    required this.id,
    required this.recipeNames,
    this.servings,
    required this.status,
    required this.totalItems,
    required this.pendingItems,
  });

  factory TodoListModel.fromJson(Map<String, dynamic> json) => TodoListModel(
        id: json['id'],
        recipeNames: List<String>.from(json['recipe_names'] ?? []),
        servings: json['servings'],
        status: json['status'] ?? 'pending',
        totalItems: json['total_items'] ?? 0,
        pendingItems: json['pending_items'] ?? 0,
      );
}
