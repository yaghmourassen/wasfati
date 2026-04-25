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

  // ⭐ ADD THIS
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

    // ⭐ ADD THIS
    this.userRatings = const {},
  });

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

      // ⭐ ADD THIS
      'userRatings': userRatings,
    };
  }

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

      // ⭐ SAFE CAST FIX
      userRatings: (map['userRatings'] != null)
          ? Map<String, double>.from(
        (map['userRatings'] as Map).map(
              (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
      )
          : {},
    );
  }
}