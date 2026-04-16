import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/user_model.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream that listens to FirebaseAuth and maps it to your UserModel
  Stream<UserModel?> get userStream {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!, doc.id);
    });
  }

  // Login user with email & password
  Future<UserModel?> login(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = credential.user!.uid;
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        // Create Firestore user doc if missing (for safety)
        final newUser = UserModel(
          id: userId,
          name: credential.user!.displayName ?? "User",
          email: credential.user!.email ?? email,
          profileImageUrl: credential.user!.photoURL,
        );
        await _firestore.collection('users').doc(userId).set(newUser.toMap());
        return newUser;
      }

      return UserModel.fromMap(doc.data()!, doc.id);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleFirebaseError(e));
    } catch (e) {
      throw Exception("Login failed. Please try again.");
    }
  }

  // Register new user and create a Firestore profile
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

      // Create new user model
      UserModel newUser = UserModel(
        id: userId,
        name: name,
        email: email,
        profileImageUrl: null,
      );

      // Save to Firestore
      await _firestore.collection('users').doc(userId).set(newUser.toMap());

      // Optionally update FirebaseAuth display name
      await credential.user!.updateDisplayName(name);

      return newUser;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleFirebaseError(e));
    } catch (e) {
      throw Exception("Registration failed. Please try again.");
    }
  }

  // Logout user
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Error handler for friendly messages
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
