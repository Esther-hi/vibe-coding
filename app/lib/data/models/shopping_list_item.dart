class ShoppingListItemModel {
  final String id;
  final String ingredientName;
  final String quantity;
  final String? estimatedPrice;
  final bool isPurchased;

  ShoppingListItemModel({
    required this.id,
    required this.ingredientName,
    required this.quantity,
    this.estimatedPrice,
    this.isPurchased = false,
  });

  factory ShoppingListItemModel.fromJson(Map<String, dynamic> json) {
    return ShoppingListItemModel(
      id: json['id'] ?? '',
      ingredientName: json['ingredient_name'] ?? '',
      quantity: json['quantity'] ?? '',
      estimatedPrice: json['estimated_price'],
      isPurchased: json['is_purchased'] ?? false,
    );
  }

  ShoppingListItemModel copyWith({
    String? id,
    String? ingredientName,
    String? quantity,
    String? estimatedPrice,
    bool? isPurchased,
  }) {
    return ShoppingListItemModel(
      id: id ?? this.id,
      ingredientName: ingredientName ?? this.ingredientName,
      quantity: quantity ?? this.quantity,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      isPurchased: isPurchased ?? this.isPurchased,
    );
  }
}
