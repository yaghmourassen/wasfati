import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/recipe_model.dart';

class RecipeController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection reference
  CollectionReference get _recipesCollection => _firestore.collection('recipes');

  /// ✅ Add a new recipe
  Future<String?> addRecipe({
    required String title,
    required String description,
    required List<String> ingredients,
  }) async {
    try {
      RecipeModel newRecipe = RecipeModel(
        title: title,
        description: description,
        ingredients: ingredients,
      );

      await _recipesCollection.add(newRecipe.toMap());
      return null; // Success
    } catch (e) {
      return e.toString(); // Return error message
    }
  }

  /// ✅ Update an existing recipe
  Future<String?> updateRecipe({
    required String id,
    required String title,
    required String description,
    required List<String> ingredients,
  }) async {
    try {
      RecipeModel updatedRecipe = RecipeModel(
        id: id,
        title: title,
        description: description,
        ingredients: ingredients,
      );

      await _recipesCollection.doc(id).update(updatedRecipe.toMap());
      return null; // Success
    } catch (e) {
      return e.toString(); // Return error message
    }
  }

  /// ✅ Delete a recipe
  Future<String?> deleteRecipe(String id) async {
    try {
      await _recipesCollection.doc(id).delete();
      return null; // Success
    } catch (e) {
      return e.toString(); // Return error message
    }
  }

  /// ✅ Fetch recipes as stream
  Stream<List<RecipeModel>> getRecipesStream() {
    return _recipesCollection
        .orderBy('title')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => RecipeModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList());
  }
}
