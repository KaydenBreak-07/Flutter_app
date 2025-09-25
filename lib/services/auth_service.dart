// File: lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Initialize GoogleSignIn compatible with v6.2.1
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      UserCredential result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user profile with name
      await result.user?.updateDisplayName(name);
      await result.user?.reload();

      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Sign in with Google - Compatible with google_sign_in ^6.2.1
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Clear any previous sign-in state for a clean start
      await _googleSignIn.signOut();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Check if we have valid tokens
      final String? accessToken = googleAuth.accessToken;
      final String? idToken = googleAuth.idToken;

      if (accessToken == null && idToken == null) {
        throw 'Failed to get authentication tokens from Google';
      }

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      print('Google Sign-In Debug Error: $e');

      // More specific error handling for common Google Sign-In issues
      String errorMessage = 'Google sign-in failed. ';

      if (e.toString().contains('network_error') || e.toString().contains('sign_in_failed')) {
        errorMessage += 'Please check your internet connection and try again.';
      } else if (e.toString().contains('sign_in_canceled')) {
        errorMessage += 'Sign-in was cancelled.';
      } else if (e.toString().contains('sign_in_required')) {
        errorMessage += 'Please try signing in again.';
      } else {
        errorMessage += 'Please try again later.';
      }

      throw errorMessage;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Sign out from both Firebase and Google
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      print('Sign out error: $e');
      throw 'Sign out failed. Please try again.';
    }
  }

  // Reset password
  Future<void> resetPassword({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Password reset failed. Please try again.';
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user != null) {
        // Sign out from Google if signed in with Google
        if (user.providerData.any((info) => info.providerId == 'google.com')) {
          await _googleSignIn.signOut();
        }

        // Delete the Firebase user account
        await user.delete();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw 'This operation requires recent authentication. Please log out and log back in, then try again.';
      }
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Account deletion failed. Please try again.';
    }
  }

  // Handle Firebase Auth exceptions with detailed error messages
  String _handleAuthException(FirebaseAuthException e) {
    print('Firebase Auth Error: ${e.code} - ${e.message}');

    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak. Use at least 6 characters with a mix of letters and numbers.';
      case 'email-already-in-use':
        return 'An account already exists with that email. Try logging in instead.';
      case 'invalid-email':
        return 'The email address is not valid. Please check and try again.';
      case 'operation-not-allowed':
        return 'This operation is not allowed. Please contact support.';
      case 'user-disabled':
        return 'This user account has been disabled. Please contact support.';
      case 'user-not-found':
        return 'No user found with this email. Please check your email or sign up.';
      case 'wrong-password':
        return 'Wrong password provided. Please try again or reset your password.';
      case 'invalid-credential':
        return 'The provided credentials are invalid. Please try again.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait a few minutes and try again.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please log out and log back in.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different credentials. Try logging in with email/password.';
      case 'invalid-verification-code':
        return 'Invalid verification code. Please try again.';
      case 'invalid-verification-id':
        return 'Invalid verification ID. Please try again.';
      default:
        return e.message ?? 'An authentication error occurred. Please try again.';
    }
  }

  // Check if user is signed in
  bool get isSignedIn => currentUser != null;

  // Get user email
  String? get userEmail => currentUser?.email;

  // Get user display name
  String? get userDisplayName => currentUser?.displayName;

  // Get user ID
  String? get userId => currentUser?.uid;

  // Reload user data
  Future<void> reloadUser() async {
    await currentUser?.reload();
  }
}