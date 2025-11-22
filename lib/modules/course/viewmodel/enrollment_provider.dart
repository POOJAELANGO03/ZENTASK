// lib/modules/course/viewmodel/enrollment_provider.dart (FULL CORRECTED CODE)

import 'package:flutter_riverpod/flutter_riverpod.dart';

class EnrollmentNotifier extends StateNotifier<Set<String>> {
  // 🔑 FIX: MUST initialize the state with an empty set {}
  EnrollmentNotifier() : super({}); 

  void unlockCourse(String courseId) {
    // Uses the spread operator to create a new Set with the added courseId
    state = {...state, courseId};
  }

  bool isEnrolled(String courseId) {
    return state.contains(courseId);
  }
}

final enrollmentProvider = StateNotifierProvider<EnrollmentNotifier, Set<String>>((ref) {
  // The provider returns the Notifier instance
  return EnrollmentNotifier(); 
});