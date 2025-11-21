// lib/core/services/firebase_auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

class FirebaseAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore instance

  // Stream to watch auth state
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // --- Authentication Methods ---

  // Sign In
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException {
      rethrow; 
    }
  }

  // Register with Email and Role (Implementation)
  Future<UserCredential> registerWithEmailAndRole({
    required String email,
    required String password,
    required String role, 
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        // Firestore write logic to save the 'role'
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(), // Use FieldValue
        });
      }
      
      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}