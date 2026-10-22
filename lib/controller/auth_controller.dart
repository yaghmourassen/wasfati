
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../model/user_model.dart';
import '../core/user_session.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ================= SESSION HELPERS =================

  void _clearSession() {
    UserSession.userId = '';
    UserSession.role = 'user';
    UserSession.isAdmin = false;
  }

  // ================= STREAM USER =================

  Stream<UserModel?> get userStream {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) {
        _clearSession();
        return null;
      }

      await user.reload();
      final refreshedUser = _auth.currentUser;

      if (refreshedUser == null || !refreshedUser.emailVerified) {
        _clearSession();
        return null;
      }

      final userId = refreshedUser.uid;
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        _clearSession();
        return null;
      }

      final data = doc.data()!;
      final role = (data['role'] as String?) ?? 'user';

      UserSession.userId = userId;
      UserSession.role = role;
      UserSession.isAdmin = role == 'admin';

      return UserModel.fromMap(data, doc.id);
    });
  }

  // ================= LOGIN =================

  Future<UserModel?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        throw Exception('Login failed. Please try again.');
      }

      await user.reload();
      final refreshedUser = _auth.currentUser;

      if (refreshedUser == null) {
        throw Exception('Login failed. Please try again.');
      }

      // Require email verification before accessing the account.
      if (!refreshedUser.emailVerified) {
        await _auth.signOut();
        _clearSession();

        throw Exception(
          'Please verify your email address before logging in.',
        );
      }

      final userId = refreshedUser.uid;
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        await _auth.signOut();
        _clearSession();

        throw Exception(
          'User profile not found. Please contact support.',
        );
      }

      final data = doc.data()!;
      final role = (data['role'] as String?) ?? 'user';

      UserSession.userId = userId;
      UserSession.role = role;
      UserSession.isAdmin = role == 'admin';

      return UserModel.fromMap(data, doc.id);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleFirebaseError(e));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Login failed. Please try again.');
    }
  }

  // ================= REGISTER =================

  Future<UserModel?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    UserCredential? credential;

    try {
      final normalizedName = name.trim();
      final normalizedEmail = email.trim();

      credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        throw Exception('Registration failed. Please try again.');
      }

      await user.updateDisplayName(normalizedName);

      final newUser = UserModel(
        id: user.uid,
        name: normalizedName,
        email: normalizedEmail,
        profileImageUrl: null,
      );

      await _firestore.collection('users').doc(user.uid).set({
        ...newUser.toMap(),
        'role': 'user',
      });

      await user.sendEmailVerification();

      UserSession.userId = user.uid;
      UserSession.role = 'user';
      UserSession.isAdmin = false;

      // The user must verify the email before logging in.
      return newUser;
    } on FirebaseAuthException catch (e) {
      if (credential?.user != null) {
        await _auth.signOut();
      }

      _clearSession();
      throw Exception(_handleFirebaseError(e));
    } catch (e) {
      if (credential?.user != null) {
        await _auth.signOut();
      }

      _clearSession();

      if (e is Exception) rethrow;
      throw Exception('Registration failed. Please try again.');
    }
  }

  // ================= RESEND VERIFICATION =================

  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please register or log in again.');
    }

    await user.reload();

    final refreshedUser = _auth.currentUser;

    if (refreshedUser == null) {
      throw Exception('Please register or log in again.');
    }

    if (refreshedUser.emailVerified) {
      return;
    }

    await refreshedUser.sendEmailVerification();
  }

  // ================= PASSWORD RESET =================

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(
        email: email.trim(),
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleFirebaseError(e));
    }
  }

  // ================= LOGOUT =================

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } finally {
      _clearSession();
    }
  }

  // ================= ERROR HANDLER =================

  String _handleFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'invalid-credential':
        return 'Invalid email or password.';

      case 'wrong-password':
        return 'Incorrect password. Please try again.';

      case 'email-already-in-use':
        return 'That email is already registered.';

      case 'invalid-email':
        return 'Please enter a valid email.';

      case 'weak-password':
        return 'Password should be at least 6 characters.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      case 'network-request-failed':
        return 'Network error. Please check your connection.';

      case 'requires-recent-login':
        return 'Please log in again to perform this action.';

      case 'operation-not-allowed':
        return 'Email and password authentication is not enabled.';

      default:
        return e.message ?? 'An unknown error occurred.';
    }
  }
}
