class RecipeModel {
  final String? id;

  final String title;
  final String description;
  final String categoryId;
  final List<String> ingredients;
  final String? imageUrl;
  final String? videoUrl;

  // 🛠️ حقول الخطوات الجديدة مع صورها الاختيارية
  final List<Map<String, dynamic>>? steps;
  final List<Map<String, dynamic>>? stepsAr;
  final List<Map<String, dynamic>>? stepsEn;

  final double rating;
  final int ratingCount;
  final int views;

  final Map<String, double> userRatings;

  // 🌍 L18N
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
    this.videoUrl,
    this.steps,
    this.stepsAr,
    this.stepsEn,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.views = 0,
    this.userRatings = const {},
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
      'videoUrl': videoUrl,
      'steps': steps,
      'stepsAr': stepsAr,
      'stepsEn': stepsEn,
      'rating': rating,
      'ratingCount': ratingCount,
      'views': views,
      'userRatings': userRatings,

      // 🛠️ تم توحيد الأسماء هنا لتطابق fromMap تماماً (بدون شرطة سفلية)
      'titleEn': titleEn,
      'titleAr': titleAr,
      'descriptionEn': descriptionEn,
      'descriptionAr': descriptionAr,
      'ingredientsEn': ingredientsEn,
      'ingredientsAr': ingredientsAr,
    };
  }

  factory RecipeModel.fromMap(String id, Map<String, dynamic> map) {
    List<Map<String, dynamic>> parseSteps(dynamic data) {
      if (data is List) {
        return data.map((e) {
          if (e is Map) {
            return {
              'text': e['text']?.toString() ?? '',
              'imageUrl': e['imageUrl']?.toString(),
            };
          } else {
            return {'text': e.toString(), 'imageUrl': null};
          }
        }).toList();
      }
      return [];
    }

    return RecipeModel(
      id: id,
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      categoryId: map['categoryId']?.toString() ?? '',
      ingredients: (map['ingredients'] is List)
          ? (map['ingredients'] as List).map((e) => e.toString()).toList()
          : [],
      imageUrl: map['imageUrl']?.toString(),
      videoUrl: map['videoUrl']?.toString(),

      steps: parseSteps(map['steps']),
      stepsAr: parseSteps(map['stepsAr']),
      stepsEn: parseSteps(map['stepsEn']),

      rating: (map['rating'] is num) ? (map['rating'] as num).toDouble() : 0.0,
      ratingCount: (map['ratingCount'] is num)
          ? (map['ratingCount'] as num).toInt()
          : 0,
      views: (map['views'] is num) ? (map['views'] as num).toInt() : 0,
      userRatings: (map['userRatings'] is Map)
          ? (map['userRatings'] as Map).map<String, double>((k, v) {
        return MapEntry(
          k.toString(),
          (v is num) ? v.toDouble() : 0.0,
        );
      })
          : {},

      titleEn: map['titleEn']?.toString() ?? '',
      titleAr: map['titleAr']?.toString() ?? '',
      descriptionEn: map['descriptionEn']?.toString() ?? '',
      descriptionAr: map['descriptionAr']?.toString() ?? '',

      ingredientsEn: (map['ingredientsEn'] is List)
          ? List<String>.from(map['ingredientsEn'])
          : [],
      ingredientsAr: (map['ingredientsAr'] is List)
          ? List<String>.from(map['ingredientsAr'])
          : [],
    );
  }
}