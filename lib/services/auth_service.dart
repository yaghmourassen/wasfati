import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../model/user_model.dart';

class AuthUserProfile {
  final UserModel user;
  final String role;

  const AuthUserProfile({
    required this.user,
    required this.role,
  });
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ================= AUTH STATE =================

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> reloadCurrentUser() async {
    await _auth.currentUser?.reload();
  }

  // ================= USER PROFILE =================

  Future<AuthUserProfile?> getUserProfile(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();

    if (!doc.exists) {
      return null;
    }

    final data = doc.data()!;
    final user = UserModel.fromMap(data, doc.id);
    final role = (data['role'] as String?) ?? 'user';

    return AuthUserProfile(
      user: user,
      role: role,
    );
  }

  // ================= LOGIN =================

  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // ================= REGISTER =================

  Future<UserCredential> register({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> updateDisplayName({
    required User user,
    required String name,
  }) {
    return user.updateDisplayName(name);
  }

  Future<void> createUserProfile(UserModel user) {
    return _firestore.collection('users').doc(user.id).set({
      ...user.toMap(),
      'role': 'user',
    });
  }

  // ================= EMAIL VERIFICATION =================

  Future<void> sendEmailVerification(User user) {
    return user.sendEmailVerification();
  }

  // ================= PASSWORD RESET =================

  Future<void> resetPassword(String email) {
    return _auth.sendPasswordResetEmail(
      email: email.trim(),
    );
  }

  // ================= LOGOUT =================

  Future<void> logout() {
    return _auth.signOut();
  }
}