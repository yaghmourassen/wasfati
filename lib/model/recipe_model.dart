class RecipeModel {
  final String? id; // Firestore document ID
  final String title;
  final String description;
  final String categoryId; // 👈 مهم جداً
  final List<String> ingredients;
  final String? imageUrl;

  RecipeModel({
    this.id,
    required this.title,
    required this.description,
    required this.categoryId, // 👈 لازم تكون موجودة
    required this.ingredients,
    this.imageUrl,
  });

  /// Convert RecipeModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'categoryId': categoryId, // 👈 مهم
      'ingredients': ingredients,
      'imageUrl': imageUrl,
    };
  }

  /// Create RecipeModel from Firestore document
  factory RecipeModel.fromMap(String id, Map<String, dynamic> map) {
    return RecipeModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      categoryId: map['categoryId'] ?? '', // 👈 مهم
      ingredients: List<String>.from(map['ingredients'] ?? []),
      imageUrl: map['imageUrl'],
    );
  }
}