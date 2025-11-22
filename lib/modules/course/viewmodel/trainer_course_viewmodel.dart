// lib/modules/course/viewmodel/trainer_course_viewmodel.dart (RECTIFIED)

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 🔑 FIX: Correct relative imports for core components
import '../../../providers.dart'; 
import '../model/course_model.dart';
import '../model/video_lesson_model.dart';
import '../service/course_service.dart'; 
import '../../auth/viewmodel/auth_state_view_model.dart'; 

// --- STATE DEFINITION (Unchanged) ---

class TrainerCourseState {
  final bool isLoading;
  final String? errorMessage;
  final List<CourseModel> trainerCourses; 
  final String? currentCourseId; 
  
  final String specialization; 
  final String profileDetails; 

  TrainerCourseState({
    this.isLoading = false,
    this.errorMessage,
    this.trainerCourses = const [],
    this.currentCourseId,
    this.specialization = '',
    this.profileDetails = '',
  });

  TrainerCourseState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<CourseModel>? trainerCourses,
    String? currentCourseId,
    String? specialization,
    String? profileDetails,
  }) {
    return TrainerCourseState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      trainerCourses: trainerCourses ?? this.trainerCourses,
      currentCourseId: currentCourseId,
      specialization: specialization ?? this.specialization,
      profileDetails: profileDetails ?? this.profileDetails,
    );
  }
}

// --- VIEWMODEL (STATENOTIFIER) (Unchanged Logic) ---

class TrainerCourseViewModel extends StateNotifier<TrainerCourseState> {
  final CourseService _courseService; 
  final String? _currentTrainerUid;

  TrainerCourseViewModel(this._courseService, this._currentTrainerUid) : super(TrainerCourseState()) {
    if (_currentTrainerUid != null) {
      listenToTrainerCourses(_currentTrainerUid!);
    }
  }

  void listenToTrainerCourses(String trainerUid) {
    _courseService.getTrainerCourses(trainerUid).listen((courses) {
      state = state.copyWith(trainerCourses: courses);
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
}

// --- RIVERPOD PROVIDER ---

final trainerCourseViewModelProvider =
    StateNotifierProvider<TrainerCourseViewModel, TrainerCourseState>((ref) {
  // 🔑 FIX: Correctly watches the typed courseServiceProvider
  final courseService = ref.watch(courseServiceProvider); 
  final authData = ref.watch(authStateViewModelProvider);
  
  String? trainerUid = authData.maybeWhen(
    data: (userModel) => userModel?.uid,
    orElse: () => null,
  );
  
  // NOTE: No need for casting if providers.dart is correctly typed
  return TrainerCourseViewModel(courseService, trainerUid);
});