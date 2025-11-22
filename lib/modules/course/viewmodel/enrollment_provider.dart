// lib/modules/course/viewmodel/enrollment_provider.dart (NEW FILE)

import 'package:flutter_riverpod/flutter_riverpod.dart';

// 🔑 This provider holds the set of Course IDs the current Learner has unlocked.
// In a real app, this would be fetched from Firestore upon login.
class EnrollmentNotifier extends StateNotifier<Set<String>> {
  EnrollmentNotifier() : super({});

  // Simulates unlocking/enrolling in a course
  void unlockCourse(String courseId) {
    state = {...state, courseId};
  }

  // Helper check method
  bool isEnrolled(String courseId) {
    return state.contains(courseId);
  }
}

final enrollmentProvider = StateNotifierProvider<EnrollmentNotifier, Set<String>>((ref) {
  return EnrollmentNotifier();
});