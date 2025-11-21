// lib/modules/auth/model/user_model.dart

import 'package:cloud_firestore/cloud_firestore.dart'; 

enum UserRole {
  // Update roles to match the project description
  trainer, // Maps to Trainer role
  learner, // Maps to Learner role
  admin,   // Maps to Admin role
  unknown,
}

class UserModel {
  final String uid;
  final String email;
  final UserRole role;
  final String? profileImageUrl; // Example of expansion

  UserModel({required this.uid, required this.email, this.role = UserRole.unknown, this.profileImageUrl});

  // Factory constructor for Firebase Auth (initial) - Not strictly used now, but good to keep
  factory UserModel.fromFirebaseUser(dynamic user) {
    if (user == null) {
      throw Exception('Firebase User is null');
    }
    return UserModel(
      uid: user.uid,
      email: user.email ?? 'N/A',
    );
  }

  // Factory constructor for Firestore (with role)
  factory UserModel.fromFirestore(String uid, Map<String, dynamic> data) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? 'N/A',
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == data['role'],
        orElse: () => UserRole.unknown,
      ),
      // Future expansion: profileImageUrl: data['profileImageUrl'],
    );
  }

  // To save data to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'role': role.toString().split('.').last, // 'trainer', 'learner', 'admin'
      'createdAt': FieldValue.serverTimestamp(), 
    };
  }
}