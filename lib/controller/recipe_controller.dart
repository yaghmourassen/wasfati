import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/recipe_model.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RecipeController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection reference
  CollectionReference get _recipesCollection =>
      _firestore.collection('recipes');

  // ======================================================
  // ☁️ CLOUDINARY UPLOAD (MVC LOGIC)
  // ======================================================
  Future<String?> uploadToCloudinary(File file) async {
    try {
      final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/dlrwrp487/image/upload",
      );

      final request = http.MultipartRequest("POST", url);

      request.fields['upload_preset'] = 'wasfaty';

      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );

      final response = await request.send();

      if (response.statusCode == 200) {
        final res = await http.Response.fromStream(response);
        final data = jsonDecode(res.body);
        return data['secure_url'];
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // ======================================================
  // ➕ ADD RECIPE
  // ======================================================
  Future<String?> addRecipe({
    required String title,
    required String description,
    required List<String> ingredients,
    String? imageUrl,
  }) async {
    try {
      RecipeModel newRecipe = RecipeModel(
        title: title,
        description: description,
        ingredients: ingredients,
        imageUrl: imageUrl,
      );

      await _recipesCollection.add(newRecipe.toMap());
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ======================================================
  // ✏️ UPDATE RECIPE
  // ======================================================
  Future<String?> updateRecipe({
    required String id,
    required String title,
    required String description,
    required List<String> ingredients,
    String? imageUrl,
  }) async {
    try {
      RecipeModel updatedRecipe = RecipeModel(
        id: id,
        title: title,
        description: description,
        ingredients: ingredients,
        imageUrl: imageUrl,
      );

      await _recipesCollection.doc(id).update(updatedRecipe.toMap());
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ======================================================
  // 🗑 DELETE RECIPE
  // ======================================================
  Future<String?> deleteRecipe(String id) async {
    try {
      await _recipesCollection.doc(id).delete();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ======================================================
  // 📡 STREAM RECIPES
  // ======================================================
  Stream<List<RecipeModel>> getRecipesStream() {
    return _recipesCollection.orderBy('title').snapshots().map(
          (snapshot) => snapshot.docs
          .map((doc) => RecipeModel.fromMap(
        doc.id,
        doc.data() as Map<String, dynamic>,
      ))
          .toList(),
    );
  }
}