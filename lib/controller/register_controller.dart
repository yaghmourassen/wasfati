import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/user_model.dart';

class RegisterController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Register user with email & password
  Future<String?> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // 1️⃣ Create user in Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;

      // 2️⃣ Create user document in Firestore
      UserModel newUser = UserModel(
        id: uid,
        name: name,
        email: email,
        profileImageUrl: null,
      );

      await _firestore.collection('users').doc(uid).set(newUser.toMap());

      // 3️⃣ Send verification email
      await userCredential.user?.sendEmailVerification();

      // 4️⃣ Immediately sign out user so they return to login
      await _auth.signOut();

      return null; // ✅ Success
    } on FirebaseAuthException catch (e) {
      return e.message; // Return Firebase error message
    } catch (e) {
      return e.toString(); // Return unexpected error
    }
  }
}
