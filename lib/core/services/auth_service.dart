// lib/core/services/auth_service.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GoogleSignInException implements Exception {
  final String message;
  GoogleSignInException(this.message);
  @override
  String toString() => message;
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // CREATE USER IN FIRESTORE
  Future<void> _addUserToFirestore(
    User user, {
    String? displayName,
    required String role,
  }) async {
    final doc = _firestore.collection('users').doc(user.uid);
    final snap = await doc.get();

    if (!snap.exists) {
      await doc.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': displayName ?? user.displayName,
        'photoURL': user.photoURL,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // SIGNUP WITH ROLE
  Future<User?> signUpWithEmail(
      String email, String password, String displayName, String role) async {
    try {
      final UserCredential res =
          await _auth.createUserWithEmailAndPassword(email: email, password: password);

      if (res.user != null) {
        await res.user!.updateDisplayName(displayName);
        await _addUserToFirestore(res.user!, displayName: displayName, role: role);
      }
      return res.user;
    } on FirebaseAuthException catch (e) {
      debugPrint("Sign Up Error: ${e.message}");
      rethrow;
    }
  }

  // GOOGLE SIGN-IN (Learner default)
  Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final auth = await googleUser.authentication;

      final cred = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );

      final UserCredential res = await _auth.signInWithCredential(cred);

      if (res.user != null) {
        await _addUserToFirestore(res.user!, role: "learner");
      }

      return res.user;
    } catch (e) {
      throw GoogleSignInException("Google Sign-In Failed");
    }
  }

  // EMAIL LOGIN
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final res = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return res.user;
    } on FirebaseAuthException catch (e) {
      debugPrint("Login Error: ${e.message}");
      rethrow;
    }
  }

  // 🔥 REQUIRED BY VIEWMODELS (Trainer + Learner)
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
    final Map<String, dynamic> data = {
      'displayName': displayName,
      'specialization': specialization,
      'profileDetails': profileDetails,
      'phoneNumber': phoneNumber,
      'address': address,
      'degree': degree,
    };

    if (profileImageUrl != null) {
      data['profileImageUrl'] = profileImageUrl;
    }

    await _firestore.collection("users").doc(uid).update(data);
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      return _auth.signOut();
    } catch (_) {}
  }
}
