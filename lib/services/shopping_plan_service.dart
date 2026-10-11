import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingPlanService {
  final _db = FirebaseFirestore.instance;

  // ADD (تم التعديل ليستخدم الـ id كمعرف للوثيقة)
  Future<void> addItem(Map<String, dynamic> data) async {
    final String id = data['id'];
    await _db.collection('shopping_items').doc(id).set(data);
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