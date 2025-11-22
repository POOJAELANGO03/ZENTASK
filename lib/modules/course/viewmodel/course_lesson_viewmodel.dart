// lib/modules/course/viewmodel/course_lesson_viewmodel.dart (NEW FILE)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers.dart';
import '../model/video_lesson_model.dart';
import '../service/course_service.dart';

// Provider that streams all lessons for a given course ID
final courseLessonsStreamProvider = StreamProvider.family<List<VideoLessonModel>, String>((ref, courseId) {
  final courseService = ref.watch(courseServiceProvider);
  return courseService.getCourseLessons(courseId);
});