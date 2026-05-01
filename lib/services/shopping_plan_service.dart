import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingPlanService {
  final _db = FirebaseFirestore.instance;

  // ADD
  Future<void> addItem(Map<String, dynamic> data) async {
    await _db.collection('shopping_items').add(data);
  }

  // DELETE
  Future<void> deleteItem(String id) async {
    await _db.collection('shopping_items').doc(id).delete();
  }

  // UPDATE
  Future<void> toggleItem(String id, bool value) async {
    await _db.collection('shopping_items').doc(id).update({
      'isDone': value,
    });
  }

  // FETCH STREAM
  Stream<QuerySnapshot> getUserItems(String userId) {
    return _db
        .collection('shopping_items')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }
}