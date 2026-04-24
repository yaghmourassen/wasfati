class RecipeModel {
  final String? id;
  final String title;
  final String description;
  final String categoryId;
  final List<String> ingredients;
  final String? imageUrl;

  final double rating;
  final int ratingCount;
  final int views;

  RecipeModel({
    this.id,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.ingredients,
    this.imageUrl,

    this.rating = 0.0,
    this.ratingCount = 0,
    this.views = 0,
  });

  /// Convert RecipeModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'categoryId': categoryId,
      'ingredients': ingredients,
      'imageUrl': imageUrl,

      'rating': rating,
      'ratingCount': ratingCount,
      'views': views,
    };
  }

  /// Create RecipeModel from Firestore document
  factory RecipeModel.fromMap(String id, Map<String, dynamic> map) {
    return RecipeModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      categoryId: map['categoryId'] ?? '',
      ingredients: List<String>.from(map['ingredients'] ?? []),
      imageUrl: map['imageUrl'],

      rating: (map['rating'] ?? 0).toDouble(),
      ratingCount: map['ratingCount'] ?? 0,
      views: map['views'] ?? 0,
    );
  }
}