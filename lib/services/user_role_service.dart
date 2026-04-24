import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/user_session.dart';

class UserRoleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      UserSession.role = "user";
      UserSession.isAdmin = false;
      return;
    }

    final doc = await _db.collection('users').doc(user.uid).get();

    final role = doc.data()?['role'] ?? "user";

    UserSession.role = role;
    UserSession.isAdmin = role == "admin";
  }
}