// lib/modules/auth/model/user_model.dart (ALTERED - Using Project Specific Roles)

import 'package:cloud_firestore/cloud_firestore.dart'; 

enum UserRole {
  trainer, // Maps to Trainer (Uploader of courses/content)
  learner, // Maps to Learner (Viewer/Unlocks courses)
  admin,   // Maps to Admin (Viewer of system analytics)
  unknown,
}

class UserModel {
  final String uid;
  final String email;
  final UserRole role;

  UserModel({required this.uid, required this.email, this.role = UserRole.unknown});

  // Factory constructor for Firestore (with role)
  factory UserModel.fromFirestore(String uid, Map<String, dynamic> data) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? 'N/A',
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == data['role'],
        orElse: () => UserRole.unknown,
      ),
    );
  }

  // To save data to Firestore
  Map<String, dynamic> toFirestore(UserRole role) {
    return {
      'email': email,
      // 🔑 FIX: Saves the correct role string (e.g., 'trainer')
      'role': role.toString().split('.').last, 
      'createdAt': FieldValue.serverTimestamp(), 
    };
  }
}