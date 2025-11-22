// lib/modules/course/service/course_service.dart (FINAL ALTERED CODE - Added logAccessRequest)

import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http; 
import '../../../core/services/cloudinary_constants.dart'; 
import '../model/course_model.dart';
import '../model/video_lesson_model.dart';

class CourseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final String _coursesCollection = 'courses';
  final String _lessonsSubcollection = 'lessons';
  
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
  
  // 3. Upload Video Lesson
  Future<void> uploadVideoAndAddLesson({
    required String courseId,
    required VideoLessonModel lesson,
    required File videoFile,
    required Function(double) onProgress, 
  }) async {
    final lessonDocRef = _firestore.collection(_coursesCollection).doc(courseId).collection(_lessonsSubcollection).doc();
    String publicId = lessonDocRef.id;
    
    // --- 1. CLOUDINARY UPLOAD ---
    
    final uri = Uri.parse(CloudinaryConstants.UPLOAD_URL);
    var request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = CloudinaryConstants.UPLOAD_PRESET
      ..fields['public_id'] = publicId 
      ..files.add(await http.MultipartFile.fromPath('file', videoFile.path));

    onProgress(0.1); 

    final streamedResponse = await request.send();
    
    final response = await http.Response.fromStream(streamedResponse); 
    
    onProgress(1.0); 

    if (response.statusCode != 200) {
      throw Exception('Cloudinary Upload Failed (${response.statusCode}): ${response.body}');
    }

    final Map<String, dynamic> responseData = json.decode(response.body);
    final String secureUrl = responseData['secure_url'];
    final int videoDuration = (responseData['duration'] as num?)?.toInt() ?? 0;

    // --- 2. FIRESTORE UPDATE ---
    
    final finalLesson = lesson.copyWith(
        id: lessonDocRef.id, 
        storageUrl: secureUrl,
        durationSeconds: videoDuration
    );

    // Save lesson data to Firestore subcollection
    await lessonDocRef.set(finalLesson.toFirestore());

    // Update lesson count on the parent Course document
    await _firestore.collection(_coursesCollection).doc(courseId).update({
      'lessonCount': FieldValue.increment(1),
    });
  }
  
  // 4. Get all courses uploaded by a specific Trainer
  Stream<List<CourseModel>> getTrainerCourses(String trainerUid) {
    return _firestore
        .collection(_coursesCollection)
        .where('trainerUid', isEqualTo: trainerUid)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => CourseModel.fromFirestore(doc)).toList()
        );
  }
  
  // 5. Calculate total enrollment
  int calculateTotalEnrollment(List<CourseModel> courses) {
    return courses.fold(0, (sum, course) => sum + course.enrolledLearners);
  }

  // 🔑 NEW IMPLEMENTATION: Log an access request for a course (Fix for Step 2)
  Future<void> logAccessRequest({
    required String courseId,
    required String learnerUid,
  }) async {
    // We log the request in a separate collection 
    await _firestore.collection('access_requests').add({
      'courseId': courseId,
      'learnerUid': learnerUid,
      'status': 'Pending', // Trainer must manually approve/change this status
      'requestedAt': FieldValue.serverTimestamp(),
    });
  }

  // --- Learner Methods ---
  
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