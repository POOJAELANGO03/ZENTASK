// lib/core/services/auth_service.dart (ALTERED - Adding updateProfileDetails)

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

// Custom exception for better error handling in the UI
class GoogleSignInException implements Exception {
  final String message;
  GoogleSignInException(this.message);

  @override
  String toString() => message.startsWith('Google Sign-In Error. Please check') 
      ? 'Configuration Error: Check Firebase SHA-1 setup.'
      : message;
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Helper function to add user data to Firestore if they don't exist
  Future<void> _addUserToFirestore(User user, {String? displayName, required String role}) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final snapshot = await userDoc.get();

    // If document doesn't exist, create it.
    if (!snapshot.exists) {
      await userDoc.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': displayName ?? user.displayName,
        'photoURL': user.photoURL,
        'role': role, // Defaulting role on first sign-in (e.g., 'learner')
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // 🔑 NEW IMPLEMENTATION: Update Profile Details in Firestore
  Future<void> updateProfileDetails({
    required String uid,
    required String displayName,
    required String specialization,
    required String profileDetails,
    required String phoneNumber,
    required String address,
    required String degree,
    String? profileImageUrl,
  }) async {
    final userDoc = _firestore.collection('users').doc(uid);
    await userDoc.update({
      'displayName': displayName,
      'specialization': specialization,
      'profileDetails': profileDetails,
      'phoneNumber': phoneNumber,
      'address': address,
      'degree': degree,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
    });
  }

  // 1. Email Sign In
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user; 
    } on FirebaseAuthException catch (e) {
      debugPrint('Failed to sign in with Email & Password: ${e.message}');
      rethrow;
    }
  }

  // 2. Email Sign Up (Adapted to include default role 'learner' for simple implementation)
  Future<User?> signUpWithEmail(String email, String password, String displayName) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (result.user != null) {
        await result.user!.updateDisplayName(displayName);
        // Defaulting role to 'learner' on signup for now.
        await _addUserToFirestore(result.user!, displayName: displayName, role: 'learner'); 
      }
      return result.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Failed to sign up with Email & Password: ${e.message}');
      rethrow;
    }
  }

  // 3. Google Sign In
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // User canceled
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result = await _auth.signInWithCredential(credential);

      if (result.user != null) {
        // Defaulting role to 'learner' on first Google Sign-In
        await _addUserToFirestore(result.user!, role: 'learner'); 
      }
      return result.user;
    } on PlatformException catch (e) {
      debugPrint('Google Sign-In PlatformException: ${e.code} - ${e.message}');
      throw GoogleSignInException(
          'Google Sign-In Error. Please check your app configuration (e.g., SHA-1 fingerprint in Firebase). Error code: ${e.code}');
    } on FirebaseAuthException catch (e) {
      debugPrint('Google Sign-In FirebaseAuthException: ${e.code} - ${e.message}');
      throw GoogleSignInException('Firebase authentication failed. ${e.message}');
    } catch (e) {
      debugPrint('An unexpected error occurred during Google Sign-In: $e');
      throw GoogleSignInException('An unexpected error occurred. Please try again.');
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }
}