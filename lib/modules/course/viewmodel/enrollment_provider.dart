import 'package:flutter_riverpod/flutter_riverpod.dart';

class EnrollmentNotifier extends StateNotifier<Set<String>> {
  EnrollmentNotifier() : super({});

  void unlockCourse(String courseId) {
    state = {...state, courseId};
  }

  bool isEnrolled(String courseId) {
    return state.contains(courseId);
  }
}

final enrollmentProvider =
    StateNotifierProvider<EnrollmentNotifier, Set<String>>((ref) {
  return EnrollmentNotifier();
});
