// lib/modules/auth/viewmodel/auth_state_view_model.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import '../../../providers.dart';
import '../model/user_model.dart';

// This provider listens to the Firebase Auth state stream, and then uses 
// switchMap to switch to the Firestore stream to fetch the UserModel/Role.

final authStateViewModelProvider = StreamProvider<UserModel?>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  final firestore = FirebaseFirestore.instance;

  // 1. Listen to the basic Firebase User stream
  return authService.authStateChanges.switchMap((User? firebaseUser) {
    if (firebaseUser == null) {
      // Not logged in: return a stream that emits null
      return Stream.value(null);
    } else {
      // Logged in: Switch to a new stream that fetches the custom user model (including role)
      return firestore.collection('users').doc(firebaseUser.uid).snapshots().map((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          // 2. Map the Firestore snapshot to our custom UserModel
          return UserModel.fromFirestore(firebaseUser.uid, snapshot.data()!);
        } else {
          // This handles cases where Auth exists, but Firestore data is missing
          return UserModel(uid: firebaseUser.uid, email: firebaseUser.email ?? 'N/A', role: UserRole.unknown);
        }
      });
    }
  });
});