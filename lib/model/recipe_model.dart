class RecipeModel {
  final String? id; // Firestore document ID
  final String title;
  final String description;
  final List<String> ingredients;
  final String? imageUrl; // ✅ NEW

  RecipeModel({
    this.id,
    required this.title,
    required this.description,
    required this.ingredients,
    this.imageUrl, // ✅ NEW
  });

  /// Convert RecipeModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'ingredients': ingredients,
      'imageUrl': imageUrl, // ✅ NEW
    };
  }

  /// Create RecipeModel from Firestore document
  factory RecipeModel.fromMap(String id, Map<String, dynamic> map) {
    return RecipeModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      ingredients: List<String>.from(map['ingredients'] ?? []),
      imageUrl: map['imageUrl'], // ✅ NEW
    );
  }
}