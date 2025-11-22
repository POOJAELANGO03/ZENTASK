// lib/modules/course/service/course_service.dart (ALTERED - Added calculateTotalEnrollment)

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/course_model.dart';
import '../model/video_lesson_model.dart';

class CourseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final String _coursesCollection = 'courses';
  final String _lessonsSubcollection = 'lessons';

  // 🔑 NEW: Method to calculate total enrollment from a list of courses
  int calculateTotalEnrollment(List<CourseModel> courses) {
    // Sums the enrolledLearners field for all courses
    return courses.fold(0, (sum, course) => sum + course.enrolledLearners);
  }
  
  // --- Trainer Methods ---

  // 1. Create a new course listing (metadata only)
  Future<String> createCourse(CourseModel course) async {
    final docRef = await _firestore.collection(_coursesCollection).add(course.toFirestore());
    return docRef.id;
  }

  // 2. Update an existing course listing metadata
  Future<void> updateCourse({
    required String courseId,
    required String title,
    required String description,
    required double price,
    required String category,
  }) async {
    await _firestore.collection(_coursesCollection).doc(courseId).update({
      'title': title,
      'description': description,
      'price': price,
      'category': category,
    });
  }
  
  // 3. Placeholder/Structure for Video Upload (Cloudinary implementation will replace the body of this)
  Future<void> uploadVideoAndAddLesson({
    required String courseId,
    required VideoLessonModel lesson,
    required File videoFile,
  }) async {
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

  // 4. Get all courses uploaded by a specific Trainer (Persistence Fix - uses Stream)
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