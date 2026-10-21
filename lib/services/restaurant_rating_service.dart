
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RestaurantRatingSummary {
  final double averageRating;
  final int ratingCount;

  const RestaurantRatingSummary({
    required this.averageRating,
    required this.ratingCount,
  });
}

class RestaurantRatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _ratingsCollection(
      String restaurantId,
      ) {
    return _firestore
        .collection('restaurant_ratings')
        .doc(restaurantId)
        .collection('ratings');
  }

  String _requireRestaurantId(String restaurantId) {
    final id = restaurantId.trim();

    if (id.isEmpty || id.contains('/')) {
      throw ArgumentError('A valid restaurant ID is required.');
    }

    return id;
  }

  String _requireUserId() {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('You must be logged in to rate a restaurant.');
    }

    return user.uid;
  }

  /// Returns the current user's rating, or null if they have not rated.
  Future<int?> getUserRating(String restaurantId) async {
    final id = _requireRestaurantId(restaurantId);
    final userId = _requireUserId();

    final document = await _ratingsCollection(id).doc(userId).get();

    if (!document.exists) {
      return null;
    }

    final data = document.data();
    final rating = data?['rating'];

    if (rating is! int || rating < 1 || rating > 5) {
      return null;
    }

    return rating;
  }

  /// Saves a rating or updates the user's existing rating.
  Future<void> submitRating({
    required String restaurantId,
    required int rating,
  }) async {
    final id = _requireRestaurantId(restaurantId);
    final userId = _requireUserId();

    if (rating < 1 || rating > 5) {
      throw ArgumentError('Rating must be between 1 and 5.');
    }

    final ratingDocument = _ratingsCollection(id).doc(userId);

    await _firestore.runTransaction((transaction) async {
      transaction.set(
        ratingDocument,
        {
          'rating': rating,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    });
  }

  /// Calculates the average and number of ratings for a restaurant.
  Future<RestaurantRatingSummary> getRatingSummary(
      String restaurantId,
      ) async {
    final id = _requireRestaurantId(restaurantId);

    // Authentication is required by the proposed Firestore rules.
    _requireUserId();

    final snapshot = await _ratingsCollection(id).get();

    var totalRating = 0;
    var validRatingCount = 0;

    for (final document in snapshot.docs) {
      final value = document.data()['rating'];

      if (value is int && value >= 1 && value <= 5) {
        totalRating += value;
        validRatingCount++;
      }
    }

    return RestaurantRatingSummary(
      averageRating: validRatingCount == 0
          ? 0.0
          : totalRating / validRatingCount,
      ratingCount: validRatingCount,
    );
  }
}
