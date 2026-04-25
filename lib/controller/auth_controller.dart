import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../model/user_model.dart';
import '../core/user_session.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ================= STREAM USER =================
  Stream<UserModel?> get userStream {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;

      // ✅ FIX: set session userId
      UserSession.userId = user.uid;

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) return null;

      final data = doc.data()!;

      final role = data['role'] ?? "user";
      UserSession.role = role;
      UserSession.isAdmin = role == "admin";

      return UserModel.fromMap(data, doc.id);
    });
  }

  // ================= LOGIN =================
  Future<UserModel?> login(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = credential.user!.uid;

      // ✅ FIX: set session userId
      UserSession.userId = userId;

      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        final newUser = UserModel(
          id: userId,
          name: credential.user!.displayName ?? "User",
          email: credential.user!.email ?? email,
          profileImageUrl: credential.user!.photoURL,
        );

        await _firestore.collection('users').doc(userId).set({
          ...newUser.toMap(),
          "role": "user",
        });

        UserSession.role = "user";
        UserSession.isAdmin = false;

        return newUser;
      }

      final data = doc.data()!;

      final role = data['role'] ?? "user";
      UserSession.role = role;
      UserSession.isAdmin = role == "admin";

      return UserModel.fromMap(data, doc.id);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleFirebaseError(e));
    } catch (e) {
      throw Exception("Login failed. Please try again.");
    }
  }

  // ================= REGISTER =================
  Future<UserModel?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = credential.user!.uid;

      // ✅ FIX: set session userId
      UserSession.userId = userId;

      UserModel newUser = UserModel(
        id: userId,
        name: name,
        email: email,
        profileImageUrl: null,
      );

      await _firestore.collection('users').doc(userId).set({
        ...newUser.toMap(),
        "role": "user",
      });

      await credential.user!.updateDisplayName(name);

      UserSession.role = "user";
      UserSession.isAdmin = false;

      return newUser;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleFirebaseError(e));
    } catch (e) {
      throw Exception("Registration failed. Please try again.");
    }
  }

  // ================= LOGOUT =================
  Future<void> logout() async {
    await _auth.signOut();

    // 🔥 reset session
    UserSession.role = "user";
    UserSession.isAdmin = false;
  }

  // ================= ERROR HANDLER =================
  String _handleFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'That email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      default:
        return e.message ?? 'An unknown error occurred.';
    }
  }
}