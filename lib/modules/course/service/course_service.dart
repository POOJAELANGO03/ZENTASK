import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/cloudinary_constants.dart';
import '../model/course_model.dart';
import '../model/video_lesson_model.dart';

class AccessRequest {
  final String id;
  final String courseId;
  final String learnerUid;
  final String trainerUid;
  final String status;
  final DateTime? requestedAt;

  AccessRequest({
    required this.id,
    required this.courseId,
    required this.learnerUid,
    required this.trainerUid,
    required this.status,
    this.requestedAt,
  });

  factory AccessRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return AccessRequest(
      id: doc.id,
      courseId: data['courseId'] ?? '',
      learnerUid: data['learnerUid'] ?? '',
      trainerUid: data['trainerUid'] ?? '',
      status: data['status'] ?? 'Pending',
      requestedAt: (data['requestedAt'] as Timestamp?)?.toDate(),
    );
  }
}

class CourseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _coursesCollection = 'courses';
  final String _lessonsSubcollection = 'lessons';
  final String _enrollmentsSubcollection = 'enrollments';

  // 1. Create a new course listing (metadata only)
  Future<String> createCourse(CourseModel course) async {
    final docRef =
        await _firestore.collection(_coursesCollection).add(course.toFirestore());
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

  // Delete course + its lessons
  Future<void> deleteCourse(String courseId) async {
    final courseRef =
        _firestore.collection(_coursesCollection).doc(courseId);

    final lessonsSnapshot =
        await courseRef.collection(_lessonsSubcollection).get();

    final batch = _firestore.batch();
    for (final doc in lessonsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(courseRef);
    await batch.commit();
  }

  // 3. Upload Video Lesson
  Future<void> uploadVideoAndAddLesson({
    required String courseId,
    required VideoLessonModel lesson,
    required File videoFile,
    required Function(double) onProgress,
  }) async {
    final lessonDocRef = _firestore
        .collection(_coursesCollection)
        .doc(courseId)
        .collection(_lessonsSubcollection)
        .doc();

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
      throw Exception(
          'Cloudinary Upload Failed (${response.statusCode}): ${response.body}');
    }

    final Map<String, dynamic> responseData = json.decode(response.body);
    final String secureUrl = responseData['secure_url'];
    final int videoDuration =
        (responseData['duration'] as num?)?.toInt() ?? 0;

    // --- 2. FIRESTORE UPDATE ---
    final finalLesson = lesson.copyWith(
      id: lessonDocRef.id,
      storageUrl: secureUrl,
      durationSeconds: videoDuration,
    );

    await lessonDocRef.set(finalLesson.toFirestore());

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
            snapshot.docs.map((doc) => CourseModel.fromFirestore(doc)).toList());
  }

  // 5. Calculate total enrollment
  int calculateTotalEnrollment(List<CourseModel> courses) {
    return courses.fold(0, (sum, course) => sum + course.enrolledLearners);
  }

  // Log an access request for a course (used by "Request Access" button)
  Future<void> logAccessRequest({
    required String courseId,
    required String learnerUid,
  }) async {
    final courseDoc =
        await _firestore.collection(_coursesCollection).doc(courseId).get();
    final courseData = courseDoc.data() as Map<String, dynamic>?;

    final String trainerUid = courseData?['trainerUid'] ?? '';

    await _firestore.collection('access_requests').add({
      'courseId': courseId,
      'learnerUid': learnerUid,
      'trainerUid': trainerUid,
      'status': 'Pending',
      'requestedAt': FieldValue.serverTimestamp(),
    });
  }

  // Enrollment method (used by Simulated Payment AND trainer approval)
  Future<void> enrollLearner({
    required String courseId,
    required String learnerUid,
  }) async {
    final courseRef =
        _firestore.collection(_coursesCollection).doc(courseId);
    final enrollmentRef =
        courseRef.collection(_enrollmentsSubcollection).doc(learnerUid);

    await _firestore.runTransaction((transaction) async {
      final enrollmentSnap = await transaction.get(enrollmentRef);

      if (!enrollmentSnap.exists) {
        transaction.set(enrollmentRef, {
          'learnerUid': learnerUid,
          'enrolledAt': FieldValue.serverTimestamp(),
        });

        transaction.update(courseRef, {
          'enrolledLearners': FieldValue.increment(1),
        });
      }
    });
  }

  // Stream access-requests for a trainer
  Stream<List<AccessRequest>> getTrainerAccessRequests(String trainerUid) {
    return _firestore
        .collection('access_requests')
        .where('trainerUid', isEqualTo: trainerUid)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AccessRequest.fromFirestore(doc)).toList());
  }

  // Trainer approves → enroll learner + mark request approved
  Future<void> approveAccessRequest({
    required String requestId,
    required String courseId,
    required String learnerUid,
  }) async {
    // 1) Enroll learner
    await enrollLearner(courseId: courseId, learnerUid: learnerUid);

    // 2) Update request status
    await _firestore.collection('access_requests').doc(requestId).update({
      'status': 'Approved',
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  // Trainer declines → only update status
  Future<void> declineAccessRequest({
    required String requestId,
  }) async {
    await _firestore.collection('access_requests').doc(requestId).update({
      'status': 'Declined',
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  // --- Learner Methods ---

  Stream<List<CourseModel>> getAllCourses() {
    return _firestore
        .collection(_coursesCollection)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => CourseModel.fromFirestore(doc)).toList());
  }

  Stream<List<VideoLessonModel>> getCourseLessons(String courseId) {
    return _firestore
        .collection(_coursesCollection)
        .doc(courseId)
        .collection(_lessonsSubcollection)
        .orderBy('orderIndex', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VideoLessonModel.fromFirestore(doc.data()!, doc.id))
            .toList());
  }
}
