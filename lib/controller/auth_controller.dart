import 'package:firebase_auth/firebase_auth.dart';

import '../model/user_model.dart';
import '../core/user_session.dart';
import '../services/auth_service.dart';

class AuthController {
  final AuthService _authService = AuthService();

  // ================= SESSION HELPERS =================

  void _clearSession() {
    UserSession.userId = '';
    UserSession.role = 'user';
    UserSession.isAdmin = false;
  }

  void _updateSession(String userId, String role) {
    UserSession.userId = userId;
    UserSession.role = role;
    UserSession.isAdmin = role == 'admin';
  }

  // ================= STREAM USER =================

  Stream<UserModel?> get userStream {
    return _authService.authStateChanges.asyncMap((user) async {
      if (user == null) {
        _clearSession();
        return null;
      }

      await _authService.reloadCurrentUser();
      final refreshedUser = _authService.currentUser;

      if (refreshedUser == null || !refreshedUser.emailVerified) {
        _clearSession();
        return null;
      }

      final profile = await _authService.getUserProfile(
        refreshedUser.uid,
      );

      if (profile == null) {
        _clearSession();
        return null;
      }

      _updateSession(refreshedUser.uid, profile.role);
      return profile.user;
    });
  }

  // ================= LOGIN =================

  Future<UserModel?> login(String email, String password) async {
    try {
      final credential = await _authService.login(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        throw Exception('Login failed. Please try again.');
      }

      await _authService.reloadCurrentUser();
      final refreshedUser = _authService.currentUser;

      if (refreshedUser == null) {
        throw Exception('Login failed. Please try again.');
      }

      if (!refreshedUser.emailVerified) {
        await _authService.logout();
        _clearSession();

        throw Exception(
          'Please verify your email address before logging in.',
        );
      }

      final profile = await _authService.getUserProfile(
        refreshedUser.uid,
      );

      if (profile == null) {
        await _authService.logout();
        _clearSession();

        throw Exception(
          'User profile not found. Please contact support.',
        );
      }

      _updateSession(refreshedUser.uid, profile.role);
      return profile.user;
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

      credential = await _authService.register(
        email: normalizedEmail,
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        throw Exception('Registration failed. Please try again.');
      }

      await _authService.updateDisplayName(
        user: user,
        name: normalizedName,
      );

      final newUser = UserModel(
        id: user.uid,
        name: normalizedName,
        email: normalizedEmail,
        profileImageUrl: null,
      );

      await _authService.createUserProfile(newUser);
      await _authService.sendEmailVerification(user);

      UserSession.userId = user.uid;
      UserSession.role = 'user';
      UserSession.isAdmin = false;

      return newUser;
    } on FirebaseAuthException catch (e) {
      if (credential?.user != null) {
        await _authService.logout();
      }

      _clearSession();
      throw Exception(_handleFirebaseError(e));
    } catch (e) {
      if (credential?.user != null) {
        await _authService.logout();
      }

      _clearSession();

      if (e is Exception) rethrow;
      throw Exception('Registration failed. Please try again.');
    }
  }

  // ================= RESEND VERIFICATION =================

  Future<void> resendVerificationEmail() async {
    final user = _authService.currentUser;

    if (user == null) {
      throw Exception('Please register or log in again.');
    }

    await _authService.reloadCurrentUser();

    final refreshedUser = _authService.currentUser;

    if (refreshedUser == null) {
      throw Exception('Please register or log in again.');
    }

    if (refreshedUser.emailVerified) {
      return;
    }

    await _authService.sendEmailVerification(refreshedUser);
  }

  // ================= PASSWORD RESET =================

  Future<void> resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleFirebaseError(e));
    }
  }

  // ================= LOGOUT =================

  Future<void> logout() async {
    try {
      await _authService.logout();
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