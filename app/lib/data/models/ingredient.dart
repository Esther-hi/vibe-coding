class Ingredient {
  final String name;
  final String category;
  final String estimatedQuantity;
  final String freshness;
  final double confidence;

  Ingredient({
    required this.name,
    required this.category,
    required this.estimatedQuantity,
    required this.freshness,
    required this.confidence,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      estimatedQuantity: json['estimated_quantity'] ?? '',
      freshness: json['freshness'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'estimated_quantity': estimatedQuantity,
      'freshness': freshness,
      'confidence': confidence,
    };
  }
}

class RecognitionResult {
  final String recognitionId;
  final List<Ingredient> ingredients;
  final String storageSuggestions;
  final String imageUrl;

  RecognitionResult({
    required this.recognitionId,
    required this.ingredients,
    required this.storageSuggestions,
    required this.imageUrl,
  });

  factory RecognitionResult.fromJson(Map<String, dynamic> json) {
    return RecognitionResult(
      recognitionId: json['recognition_id'] ?? '',
      ingredients: (json['ingredients'] as List?)
          ?.map((e) => Ingredient.fromJson(e))
          .toList() ?? [],
      storageSuggestions: json['storage_suggestions'] ?? '',
      imageUrl: json['image_url'] ?? '',
    );
  }
}
