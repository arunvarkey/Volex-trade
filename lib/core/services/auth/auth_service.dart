import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Wrapper service for Firebase Authentication.
/// Used by UI screens to abstract Firebase implementation.
class AuthService {
  // Lazy so construction never touches Firebase (safe on web where Firebase
  // may not be configured).
  FirebaseAuth get _auth => FirebaseAuth.instance;

  // Lazy: constructing GoogleSignIn on web asserts if no client ID meta tag
  // is configured, so defer until Google sign-in is actually used.
  GoogleSignIn? _googleSignInInstance;
  GoogleSignIn get _googleSignIn => _googleSignInInstance ??= GoogleSignIn();

  /// Returns the currently signed-in user, or null if auth is unavailable.
  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Signs in a user with Google.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // The user canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    } catch (e) {
      rethrow;
    }
  }

  /// Signs in a user with email and password.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    }
  }

  /// Signs up a user with email and password.
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    }
  }

  /// Sends a password reset email to the specified address.
  Future<void> resetPassword({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Sends a verification email to the current user.
  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  /// Updates the current user's display name.
  Future<void> updateDisplayName(String name) async {
    await _auth.currentUser?.updateDisplayName(name);
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
}

String _mapFirebaseError(String code) {
  switch (code) {
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'Invalid email or password';
    case 'email-already-in-use':
      return 'An account already exists for that email.';
    case 'too-many-requests':
      return 'Too many attempts. Please try again later.';
    default:
      return 'Authentication failed. Please try again.';
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}
