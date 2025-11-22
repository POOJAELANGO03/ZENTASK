// lib/modules/course/viewmodel/learner_course_viewmodel.dart (NEW FILE)

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers.dart';
import '../model/course_model.dart';
import '../service/course_service.dart';

// --- STATE DEFINITION ---

class LearnerCourseState {
  final bool isLoading;
  final String? errorMessage;
  final List<CourseModel> allCourses; // Full list fetched from Firestore
  final String searchQuery;
  final String selectedCategory; // Used for filtering
  final List<CourseModel> enrolledCourses; // Courses the Learner has unlocked (Mock state)

  LearnerCourseState({
    this.isLoading = true,
    this.errorMessage,
    this.allCourses = const [],
    this.searchQuery = '',
    this.selectedCategory = 'All',
    this.enrolledCourses = const [],
  });

  LearnerCourseState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<CourseModel>? allCourses,
    String? searchQuery,
    String? selectedCategory,
    List<CourseModel>? enrolledCourses,
  }) {
    return LearnerCourseState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      allCourses: allCourses ?? this.allCourses,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      enrolledCourses: enrolledCourses ?? this.enrolledCourses,
    );
  }
}

// --- VIEWMODEL (STATENOTIFIER) ---

class LearnerCourseViewModel extends StateNotifier<LearnerCourseState> {
  final CourseService _courseService;

  LearnerCourseViewModel(this._courseService) : super(LearnerCourseState()) {
    _listenToAllCourses();
  }

  // Stream Listener for all courses
  void _listenToAllCourses() {
    _courseService.getAllCourses().listen((courses) {
      // 🔑 Mock Enrollment: For testing, let's assume the first course is enrolled
      final List<CourseModel> mockEnrollment = courses.isNotEmpty ? [courses.first] : [];
      
      state = state.copyWith(
        allCourses: courses,
        enrolledCourses: mockEnrollment, 
        isLoading: false,
      );
    }).onError((error) {
       state = state.copyWith(
        errorMessage: 'Failed to fetch all courses: $error',
        isLoading: false,
       );
    });
  }

  // Logic to apply search/filter
  void applyFilter({String? search, String? category}) {
    state = state.copyWith(
      searchQuery: search ?? state.searchQuery,
      selectedCategory: category ?? state.selectedCategory,
    );
  }
  
  // Method to get the filtered list (used by the View)
  List<CourseModel> get filteredCourses {
    List<CourseModel> courses = state.allCourses;

    // 1. Filter by Category
    if (state.selectedCategory != 'All') {
      courses = courses.where((c) => c.category == state.selectedCategory).toList();
    }

    // 2. Filter by Search Query
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      courses = courses.where((c) => 
        c.title.toLowerCase().contains(query) || 
        c.description.toLowerCase().contains(query)
      ).toList();
    }
    
    return courses;
  }
}

// --- RIVERPOD PROVIDER ---

final learnerCourseViewModelProvider =
    StateNotifierProvider<LearnerCourseViewModel, LearnerCourseState>((ref) {
  final courseService = ref.watch(courseServiceProvider);
  return LearnerCourseViewModel(courseService);
});