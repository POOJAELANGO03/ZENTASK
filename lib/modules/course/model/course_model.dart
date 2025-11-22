// lib/modules/course/model/course_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class CourseModel {
  final String id;
  final String trainerUid; 
  final String title;
  final String description;
  final double price;
  final String category;
  final double rating;
  final int enrolledLearners;
  final int lessonCount; 

  CourseModel({
    required this.id,
    required this.trainerUid,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    this.rating = 0.0,
    this.enrolledLearners = 0,
    this.lessonCount = 0, 
  });

  // Factory constructor to create from Firestore Document
  factory CourseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Course data is null');
    }

    return CourseModel(
      id: doc.id,
      trainerUid: data['trainerUid'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      category: data['category'] ?? 'General',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      enrolledLearners: data['enrolledLearners'] ?? 0,
      lessonCount: data['lessonCount'] ?? 0, 
    );
  }

  // Convert model to Map for Firestore (used by Trainer when uploading)
  Map<String, dynamic> toFirestore() {
    return {
      'trainerUid': trainerUid,
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'rating': rating,
      'enrolledLearners': enrolledLearners,
      'lessonCount': lessonCount,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}