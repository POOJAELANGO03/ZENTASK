// lib/modules/course/service/course_service.dart (RECTIFIED - Firebase Storage Removed)

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
// REMOVED: import 'package:firebase_storage/firebase_storage.dart'; 
import '../model/course_model.dart';
import '../model/video_lesson_model.dart';

class CourseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // REMOVED: final FirebaseStorage _storage = FirebaseStorage.instance; 
  
  final String _coursesCollection = 'courses';
  final String _lessonsSubcollection = 'lessons';
  
  // --- Trainer Methods ---

  // 1. Create a new course listing (metadata only)
  Future<String> createCourse(CourseModel course) async {
    final docRef = await _firestore.collection(_coursesCollection).add(course.toFirestore());
    return docRef.id;
  }
  
  // 2. Placeholder/Structure for Video Upload (Cloudinary implementation will replace the body of this)
  Future<void> uploadVideoAndAddLesson({
    required String courseId,
    required VideoLessonModel lesson,
    required File videoFile,
  }) async {
    // 🔑 CLOUDINARY INTEGRATION POINT 
    
    // Simulate Cloudinary/Storage Upload
    await Future.delayed(const Duration(seconds: 1));
    const String simulatedUrl = "https://cloudinary.com/simulated-video-url/12345.mp4";
    
    final lessonDocRef = _firestore.collection(_coursesCollection).doc(courseId).collection(_lessonsSubcollection).doc();

    final finalLesson = lesson.copyWith(id: lessonDocRef.id, storageUrl: simulatedUrl);

    // Save lesson data to Firestore subcollection
    await lessonDocRef.set(finalLesson.toFirestore());

    // Update lesson count on the parent Course document
    await _firestore.collection(_coursesCollection).doc(courseId).update({
      'lessonCount': FieldValue.increment(1),
    });
  }

  // 3. Get all courses uploaded by a specific Trainer
  Stream<List<CourseModel>> getTrainerCourses(String trainerUid) {
    return _firestore
        .collection(_coursesCollection)
        .where('trainerUid', isEqualTo: trainerUid)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => CourseModel.fromFirestore(doc)).toList()
        );
  }

  // --- Learner Methods (Placeholder) ---
  
  Stream<List<CourseModel>> getAllCourses() {
    return _firestore
        .collection(_coursesCollection)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => CourseModel.fromFirestore(doc)).toList()
        );
  }

  Stream<List<VideoLessonModel>> getCourseLessons(String courseId) {
    return _firestore
        .collection(_coursesCollection)
        .doc(courseId)
        .collection(_lessonsSubcollection)
        .orderBy('orderIndex', descending: false) 
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => VideoLessonModel.fromFirestore(doc.data()!, doc.id)).toList()
        );
  }
}