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

  // 🔥 NEW: per-user ratings (IMPORTANT)
  final Map<String, double> userRatings;

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

    // 🔥 NEW
    this.userRatings = const {},
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

      // 🔥 NEW
      'userRatings': userRatings,
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

      // 🔥 NEW SAFE CONVERSION
      userRatings: Map<String, double>.from(
        (map['userRatings'] ?? {}),
      ),
    );
  }
}