import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> deleteCurrentUserAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final uid = user.uid;

    // 🛒 DELETE SHOPPING LIST
    final shopping = await _db
        .collection('shopping_items')
        .where('userId', isEqualTo: uid)
        .get();

    for (var doc in shopping.docs) {
      await doc.reference.delete();
    }

    // 👤 DELETE USER DOC
    await _db.collection('users').doc(uid).delete();

    // ❤️ DELETE FAVORITES (if subcollection)
    final favs = await _db
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .get();

    for (var doc in favs.docs) {
      await doc.reference.delete();
    }

    // 🔥 DELETE AUTH ACCOUNT
    await user.delete();
  }
  Future<void> reauthenticate(String password) async {
    final user = FirebaseAuth.instance.currentUser;

    final credential = EmailAuthProvider.credential(
      email: user!.email!,
      password: password,
    );

    await user.reauthenticateWithCredential(credential);
  }
}