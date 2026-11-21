import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth? _customAuth;
  bool _googleSignInInitialized = false;

  AuthService({FirebaseAuth? auth}) : _customAuth = auth;

  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Currently signed in user (null if offline/unauthenticated)
  User? get currentUser => _auth.currentUser;

  Future<void> _ensureGoogleSignInInitialized() async {
    if (!_googleSignInInitialized) {
      try {
        await GoogleSignIn.instance.initialize();
      } catch (e) {
        debugPrint('GoogleSignIn.initialize notice: $e');
      }
      _googleSignInInitialized = true;
    }
  }

  /// Sign in with Google with platform-adaptive fallbacks
  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        final UserCredential userCredential =
            await _auth.signInWithPopup(googleProvider);
        return userCredential.user;
      }

      await _ensureGoogleSignInInitialized();
      final GoogleSignInAccount googleAccount =
          await GoogleSignIn.instance.authenticate();

      final GoogleSignInAuthentication googleAuth = googleAccount.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      return userCredential.user;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        // User voluntarily dismissed the sign-in modal
        return null;
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign out from Firebase and Google
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Ignore if google sign in signout fails
    }
    await _auth.signOut();
  }
}
