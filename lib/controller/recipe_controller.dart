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
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // ================= CREATE =================
  Future<String?> addRecipe({
    required String title,
    required String description,
    required List<String> ingredients,
    String? imageUrl,
  }) async {
    try {
      if (title.isEmpty || description.isEmpty) {
        return "Title and description are required";
      }

      RecipeModel recipe = RecipeModel(
        title: title,
        description: description,
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

  // ================= READ =================
  Stream<List<RecipeModel>> getRecipesStream() {
    return _recipesCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => RecipeModel.fromMap(
        doc.id,
        doc.data() as Map<String, dynamic>,
      ))
          .toList(),
    );
  }

  // ================= UPDATE =================
  Future<String?> updateRecipe({
    required String id,
    required String title,
    required String description,
    required List<String> ingredients,
    String? imageUrl,
  }) async {
    try {
      await _recipesCollection.doc(id).update({
        "title": title,
        "description": description,
        "ingredients": ingredients,
        "imageUrl": imageUrl,
      });

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ================= DELETE =================
  Future<String?> deleteRecipe(String id) async {
    try {
      await _recipesCollection.doc(id).delete();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}