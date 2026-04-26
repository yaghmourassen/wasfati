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
      'userRatings': userRatings,
    };
  }

  factory RecipeModel.fromMap(String id, Map<String, dynamic> map) {
    return RecipeModel(
      id: id,

      // 🔥 SAFE STRING CONVERSION (very important)
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      categoryId: map['categoryId']?.toString() ?? '',

      // 🔥 SAFE LIST CONVERSION
      ingredients: (map['ingredients'] is List)
          ? (map['ingredients'] as List)
          .map((e) => e.toString())
          .toList()
          : [],

      imageUrl: map['imageUrl']?.toString(),

      // 🔥 SAFE NUMBERS
      rating: (map['rating'] is num)
          ? (map['rating'] as num).toDouble()
          : 0.0,

      ratingCount: (map['ratingCount'] is num)
          ? (map['ratingCount'] as num).toInt()
          : 0,

      views: (map['views'] is num)
          ? (map['views'] as num).toInt()
          : 0,

      // 🔥 SAFE MAP CONVERSION (FIX FOR YOUR ERROR)
      userRatings: (map['userRatings'] is Map)
          ? (map['userRatings'] as Map).map<String, double>((k, v) {
        return MapEntry(
          k.toString(),
          (v is num) ? v.toDouble() : 0.0,
        );
      })
          : {},
    );
  }
}