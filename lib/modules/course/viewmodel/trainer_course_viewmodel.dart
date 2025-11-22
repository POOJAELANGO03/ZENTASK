// lib/modules/course/viewmodel/trainer_course_viewmodel.dart (ALTERED - Added Enrollment Stats)

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers.dart'; 
import '../model/course_model.dart';
import '../model/video_lesson_model.dart';
import '../service/course_service.dart'; 
import '../../auth/viewmodel/auth_state_view_model.dart'; 

// --- STATE DEFINITION ---

class TrainerCourseState {
  final bool isLoading;
  final String? errorMessage;
  final List<CourseModel> trainerCourses; 
  final String? currentCourseId; 
  
  final String specialization; 
  final String profileDetails; 
  
  // 🔑 NEW: Statistics fields
  final int totalEnrollment; 
  final double totalRevenueEstimate; // Placeholder for future use

  TrainerCourseState({
    this.isLoading = false,
    this.errorMessage,
    this.trainerCourses = const [],
    this.currentCourseId,
    this.specialization = '',
    this.profileDetails = '',
    this.totalEnrollment = 0, // Initialize new fields
    this.totalRevenueEstimate = 0.0,
  });

  TrainerCourseState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<CourseModel>? trainerCourses,
    String? currentCourseId,
    String? specialization,
    String? profileDetails,
    int? totalEnrollment,
    double? totalRevenueEstimate,
  }) {
    return TrainerCourseState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      trainerCourses: trainerCourses ?? this.trainerCourses,
      currentCourseId: currentCourseId,
      specialization: specialization ?? this.specialization,
      profileDetails: profileDetails ?? this.profileDetails,
      totalEnrollment: totalEnrollment ?? this.totalEnrollment,
      totalRevenueEstimate: totalRevenueEstimate ?? this.totalRevenueEstimate,
    );
  }
}

// --- VIEWMODEL (STATENOTIFIER) ---

class TrainerCourseViewModel extends StateNotifier<TrainerCourseState> {
  final CourseService _courseService; 
  final String? _currentTrainerUid;

  TrainerCourseViewModel(this._courseService, this._currentTrainerUid) : super(TrainerCourseState()) {
    if (_currentTrainerUid != null) {
      listenToTrainerCourses(_currentTrainerUid!);
    }
  }

  // 🔑 ALTERED: Update state with calculated metrics
  void listenToTrainerCourses(String trainerUid) {
    _courseService.getTrainerCourses(trainerUid).listen((courses) {
      // Calculate derived statistics
      final int enrollment = _courseService.calculateTotalEnrollment(courses);
      
      state = state.copyWith(
          trainerCourses: courses, 
          totalEnrollment: enrollment,
      );
    }).onError((error) {
       state = state.copyWith(errorMessage: 'Failed to fetch courses: $error');
    });
  }
  
  Future<void> saveProfileDetails({
    required String specialization,
    required String profileDetails,
  }) async {
    state = state.copyWith(specialization: specialization, profileDetails: profileDetails);
    await Future.delayed(const Duration(milliseconds: 500)); 
  }
  
  Future<String?> createCourseListing({
    required String title,
    required String description,
    required double price,
    required String category,
  }) async {
    if (_currentTrainerUid == null) {
      state = state.copyWith(errorMessage: 'Authentication error. Please log in again.');
      return null;
    }
    
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final newCourse = CourseModel( 
        id: '', 
        trainerUid: _currentTrainerUid!,
        title: title,
        description: description,
        price: price,
        category: category,
        lessonCount: 0,
      );
      
      final courseId = await _courseService.createCourse(newCourse);
      
      state = state.copyWith(
        isLoading: false,
        currentCourseId: courseId, 
      );
      return courseId;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to create course: $e');
      return null;
    }
  }

  Future<void> updateCourseListing({
    required String courseId,
    required String title,
    required String description,
    required double price,
    required String category,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _courseService.updateCourse(
        courseId: courseId,
        title: title,
        description: description,
        price: price,
        category: category,
      );
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to update course: $e');
    }
  }
}

// --- RIVERPOD PROVIDER (Unchanged) ---

final trainerCourseViewModelProvider =
    StateNotifierProvider<TrainerCourseViewModel, TrainerCourseState>((ref) {
  final courseService = ref.watch(courseServiceProvider); 
  final authData = ref.watch(authStateViewModelProvider);
  
  String? trainerUid = authData.maybeWhen(
    data: (userModel) => userModel?.uid,
    orElse: () => null,
  );
  
  return TrainerCourseViewModel(courseService, trainerUid);
});