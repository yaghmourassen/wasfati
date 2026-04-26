class RecipeModel {
  final String? id;

  // الحالي (يبقى كما هو)
  final String title;
  final String description;
  final String categoryId;
  final List<String> ingredients;
  final String? imageUrl;

  final double rating;
  final int ratingCount;
  final int views;

  final Map<String, double> userRatings;

  // 🌍 NEW (L18N ONLY - ADDITION)
  final String? titleEn;
  final String? titleAr;

  final String? descriptionEn;
  final String? descriptionAr;

  final List<String>? ingredientsEn;
  final List<String>? ingredientsAr;

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

    // NEW
    this.titleEn,
    this.titleAr,
    this.descriptionEn,
    this.descriptionAr,
    this.ingredientsEn,
    this.ingredientsAr,
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

      // NEW
      'title_en': titleEn,
      'title_ar': titleAr,
      'description_en': descriptionEn,
      'description_ar': descriptionAr,
      'ingredients_en': ingredientsEn,
      'ingredients_ar': ingredientsAr,
    };
  }

  factory RecipeModel.fromMap(String id, Map<String, dynamic> map) {
    return RecipeModel(
      id: id,

      // ORIGINAL (KEEP WORKING)
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      categoryId: map['categoryId']?.toString() ?? '',

      ingredients: (map['ingredients'] is List)
          ? (map['ingredients'] as List)
          .map((e) => e.toString())
          .toList()
          : [],

      imageUrl: map['imageUrl']?.toString(),

      rating: (map['rating'] is num)
          ? (map['rating'] as num).toDouble()
          : 0.0,

      ratingCount: (map['ratingCount'] is num)
          ? (map['ratingCount'] as num).toInt()
          : 0,

      views: (map['views'] is num)
          ? (map['views'] as num).toInt()
          : 0,

      userRatings: (map['userRatings'] is Map)
          ? (map['userRatings'] as Map).map<String, double>((k, v) {
        return MapEntry(
          k.toString(),
          (v is num) ? v.toDouble() : 0.0,
        );
      })
          : {},

      // NEW (OPTIONAL FIELDS)
      titleEn: map['title_en']?.toString(),
      titleAr: map['title_ar']?.toString(),
      descriptionEn: map['description_en']?.toString(),
      descriptionAr: map['description_ar']?.toString(),

      ingredientsEn: (map['ingredients_en'] is List)
          ? List<String>.from(map['ingredients_en'])
          : null,

      ingredientsAr: (map['ingredients_ar'] is List)
          ? List<String>.from(map['ingredients_ar'])
          : null,
    );
  }
}