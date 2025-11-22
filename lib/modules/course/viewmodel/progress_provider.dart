// lib/modules/course/viewmodel/progress_provider.dart (NEW FILE)

import 'package:flutter_riverpod/flutter_riverpod.dart';

// This provider holds the set of completed Lesson IDs
class ProgressNotifier extends StateNotifier<Set<String>> {
  // FIX: Initialize the state with an empty set {}
  ProgressNotifier() : super({});

  void completeLesson(String lessonId) {
    // Uses the spread operator to create a new, immutable Set with the added lessonId
    state = {...state, lessonId};
  }

  bool isCompleted(String lessonId) {
    return state.contains(lessonId);
  }
}

final progressProvider = StateNotifierProvider<ProgressNotifier, Set<String>>((ref) {
  return ProgressNotifier();
});