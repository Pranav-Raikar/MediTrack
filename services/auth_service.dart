// ─────────────────────────────────────────────────────────────────────────────
// services/auth_service.dart  —  Firebase Authentication
//
// Wraps Firebase Auth methods so screens don't have Firebase code directly.
// This is called "separation of concerns" — good coding practice!
// ─────────────────────────────────────────────────────────────────────────────

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;

  /// Get the currently logged-in user (null if not logged in)
  static User? get currentUser => _auth.currentUser;

  /// Create a new account with email + password
  static Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Log in with existing email + password
  static Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Log out the current user
  static Future<void> signOut() async {
    await _auth.signOut();
  }
}
