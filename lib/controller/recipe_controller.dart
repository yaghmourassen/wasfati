import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/recipe_model.dart';
import '../core/user_session.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RecipeController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _recipesCollection =>
      _firestore.collection('recipes');

  // ================= ADMIN CHECK =================
  bool _isAdmin() {
    return UserSession.isAdmin;
  }

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
      if (!_isAdmin()) {
        throw Exception("Unauthorized: Admin only");
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

      // ⭐ INITIAL VALUES
      data['rating'] = 0.0;
      data['ratingCount'] = 0;
      data['views'] = 0;

      await _recipesCollection.add(data);

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ================= READ =================
  Stream<List<RecipeModel>> getRecipesStream() {
    return FirebaseFirestore.instance
        .collection('recipes')
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
      if (!_isAdmin()) {
        throw Exception("Unauthorized: Admin only");
      }

      await _recipesCollection.doc(id).update({
        "title": title,
        "description": description,
        "categoryId": categoryId,
        "ingredients": ingredients,
        "imageUrl": imageUrl,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ================= DELETE =================
  Future<String?> deleteRecipe(String id) async {
    try {
      if (!_isAdmin()) {
        throw Exception("Unauthorized: Admin only");
      }

      await _recipesCollection.doc(id).delete();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ================= ⭐ RATE RECIPE =================
  Future<void> rateRecipe({
    required String recipeId,
    required double rating,
    required String userId,
  }) async {
    final docRef =
    FirebaseFirestore.instance.collection('recipes').doc(recipeId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      final data = snapshot.data() as Map<String, dynamic>;

      Map<String, dynamic> userRatings =
      Map<String, dynamic>.from(data['userRatings'] ?? {});

      // save/update user rating
      userRatings[userId] = rating;

      // calculate average
      double total = 0;

      userRatings.forEach((key, value) {
        total += (value as num).toDouble();
      });

      double avg = userRatings.isNotEmpty
          ? total / userRatings.length
          : 0.0;

      transaction.update(docRef, {
        'userRatings': userRatings,
        'rating': avg,
        'ratingCount': userRatings.length,
      });
    });
  }

  // ================= 👁 INCREASE VIEWS =================
  Future<void> increaseViews(String recipeId) async {
    await _recipesCollection.doc(recipeId).update({
      'views': FieldValue.increment(1),
    });
  }
}