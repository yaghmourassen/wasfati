import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/comment_model.dart';
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
// ================= CREATE =================
  Future<String?> addRecipe({
    required String title,
    required String description,
    required String categoryId,
    required List<String> ingredients,
    String? imageUrl,
    String? videoUrl, // 👈 1. أضف هذا المعلم الجديد

    // 🌍 NEW (L18N INPUTS)
    String? titleEn,
    String? titleAr,
    String? descriptionEn,
    String? descriptionAr,
    List<String>? ingredientsEn,
    List<String>? ingredientsAr, required List<Map<String, dynamic>> stepsEn, required List<Map<String, dynamic>> stepsAr, required List<Map<String, dynamic>> steps,
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
        videoUrl: videoUrl, // 👈 2. مرره هنا

        // NEW
        titleEn: titleEn,
        titleAr: titleAr,
        descriptionEn: descriptionEn,
        descriptionAr: descriptionAr,
        ingredientsEn: ingredientsEn,
        ingredientsAr: ingredientsAr,
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
// ================= UPDATE =================
  Future<String?> updateRecipe({
    required String id,
    required String title,
    required String description,
    required String categoryId,
    required String? imageUrl,
    required String? videoUrl, // 👈 1. أضف هذا المعلم الجديد
    required String titleEn,
    required String titleAr,
    required String descriptionEn,
    required String descriptionAr,
    required List<String> ingredients,
    required List<String> ingredientsEn,
    required List<String> ingredientsAr, required List<Map<String, dynamic>> steps, required List<Map<String, dynamic>> stepsAr, required List<Map<String, dynamic>> stepsEn,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('recipes')
          .doc(id)
          .update({
        "title": title,
        "description": description,
        "categoryId": categoryId,
        "imageUrl": imageUrl,
        "videoUrl": videoUrl, // 👈 2. تحديثه في قاعدة البيانات

        "titleEn": titleEn,
        "titleAr": titleAr,
        "descriptionEn": descriptionEn,
        "descriptionAr": descriptionAr,

        "ingredients": ingredients,
        "ingredientsEn": ingredientsEn,
        "ingredientsAr": ingredientsAr,
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

  Future<void> toggleFavorite({
    required String userId,
    required String recipeId,
  }) async {
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(recipeId);

    final doc = await ref.get();

    if (doc.exists) {
      // ❌ remove favorite
      await ref.delete();
    } else {
      // ❤️ add favorite
      await ref.set({
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
  Stream<bool> isFavorite(String userId, String recipeId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(recipeId)
        .snapshots()
        .map((doc) => doc.exists);
  }
  Stream<List<String>> getFavoriteIds(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => doc.id).toList());
  }
  Stream<List<RecipeModel>> getFavoriteRecipes(String userId) {
    return getFavoriteIds(userId).asyncMap((ids) async {
      if (ids.isEmpty) return [];

      final snapshot = await FirebaseFirestore.instance
          .collection('recipes')
          .where(FieldPath.documentId, whereIn: ids)
          .get();

      return snapshot.docs
          .map((doc) => RecipeModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }
  // ================= 💬 ADD COMMENT =================
  Future<void> addComment({
    required String recipeId,
    required String userId,
    required String text,
  }) async {
    // Optional: Fetch the current user's name if you want to display it properly
    // For now, we can fetch from a users collection or use a fallback name
    String userName = "Chef";
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists && userDoc.data() != null) {
        userName = userDoc.data()!['fullName'] ?? userDoc.data()!['name'] ?? "Chef";
      }
    } catch (_) {}

    await _recipesCollection
        .doc(recipeId)
        .collection('comments')
        .add({
      'userId': userId,
      'userName': userName,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ================= 💬 GET COMMENTS STREAM =================
  Stream<List<CommentModel>> getCommentsStream(String recipeId) {
    return _recipesCollection
        .doc(recipeId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Convert Firebase Timestamp to ISO string if needed for parsing
        if (data['timestamp'] is Timestamp) {
          data['timestamp'] = (data['timestamp'] as Timestamp).toDate().toIso8601String();
        }
        return CommentModel.fromMap(doc.id, data);
      }).toList();
    });
  }

  // ================= 💬 SAVE OR UPDATE COMMENT (1 per user) =================
  Future<void> saveOrUpdateComment({
    required String recipeId,
    required String userId,
    required String text,
  }) async {
    String userName = "Chef";
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists && userDoc.data() != null) {
        userName = userDoc.data()!['fullName'] ?? userDoc.data()!['name'] ?? "Chef";
      }
    } catch (_) {}

    // Using userId as doc ID guarantees 1 comment per user & prevents permission clashes
    await _recipesCollection
        .doc(recipeId)
        .collection('comments')
        .doc(userId)
        .set({
      'userId': userId,
      'userName': userName,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ================= 💬 DELETE COMMENT =================
  Future<void> deleteComment({
    required String recipeId,
    required String userId,
  }) async {
    await _recipesCollection
        .doc(recipeId)
        .collection('comments')
        .doc(userId)
        .delete();
  }
}