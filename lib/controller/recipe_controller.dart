import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/recipe_model.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RecipeController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _recipesCollection =>
      _firestore.collection('recipes');

  // ================= CLOUDINARY =================
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
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // ================= CREATE =================
  Future<String?> addRecipe({
    required String title,
    required String description,
    required String categoryId,
    required List<String> ingredients,
    String? imageUrl,
  }) async {
    try {
      if (title.trim().isEmpty || description.trim().isEmpty) {
        return "Title and description are required";
      }

      if (categoryId.trim().isEmpty) {
        return "Category is required";
      }

      final recipe = RecipeModel(
        title: title,
        description: description,
        categoryId: categoryId,
        ingredients: ingredients,
        imageUrl: imageUrl,
      );

      final data = recipe.toMap();
      data['createdAt'] = FieldValue.serverTimestamp();

      await _recipesCollection.add(data);

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ================= READ ALL =================
  Stream<List<RecipeModel>> getRecipesStream() {
    return _recipesCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return RecipeModel.fromMap(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();
    });
  }

  // ================= READ BY CATEGORY =================
  Stream<List<RecipeModel>> getRecipesByCategory(String categoryId) {
    return _recipesCollection
        .where('categoryId', isEqualTo: categoryId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return RecipeModel.fromMap(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();
    });
  }

  // ================= UPDATE =================
  Future<String?> updateRecipe({
    required String id,
    required String title,
    required String description,
    required String categoryId,
    required List<String> ingredients,
    String? imageUrl,
  }) async {
    try {
      if (id.isEmpty) return "Invalid recipe ID";

      if (title.trim().isEmpty || description.trim().isEmpty) {
        return "Title and description are required";
      }

      if (categoryId.trim().isEmpty) {
        return "Category is required";
      }

      await _recipesCollection.doc(id).update({
        "title": title,
        "description": description,
        "categoryId": categoryId,
        "ingredients": ingredients,
        "imageUrl": imageUrl,
        "updatedAt": FieldValue.serverTimestamp(), // ✅ professional touch
      });

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ================= DELETE =================
  Future<String?> deleteRecipe(String id) async {
    try {
      if (id.isEmpty) return "Invalid recipe ID";

      await _recipesCollection.doc(id).delete();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}