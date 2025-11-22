// lib/modules/course/viewmodel/learner_course_viewmodel.dart (FULL FINAL CODE)

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers.dart';
import '../model/course_model.dart';
import '../service/course_service.dart';
import '../model/video_lesson_model.dart'; 
import 'enrollment_provider.dart'; 

// --- STATE DEFINITION ---

class LearnerCourseState {
  final bool isLoading;
  final String? errorMessage;
  final List<CourseModel> allCourses; 
  final String searchQuery;
  final String selectedCategory;
  final List<CourseModel> enrolledCourses; 

  final double maxPriceFilter; 
  final double minRatingFilter; 

  LearnerCourseState({
    this.isLoading = true,
    this.errorMessage,
    this.allCourses = const [],
    this.searchQuery = '',
    this.selectedCategory = 'All',
    this.enrolledCourses = const [],
    this.maxPriceFilter = 100000.0, 
    this.minRatingFilter = 0.0,
  });

  LearnerCourseState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<CourseModel>? allCourses,
    String? searchQuery,
    String? selectedCategory,
    List<CourseModel>? enrolledCourses,
    double? maxPriceFilter,
    double? minRatingFilter,
  }) {
    return LearnerCourseState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      allCourses: allCourses ?? this.allCourses,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      enrolledCourses: enrolledCourses ?? this.enrolledCourses,
      maxPriceFilter: maxPriceFilter ?? this.maxPriceFilter,
      minRatingFilter: minRatingFilter ?? this.minRatingFilter,
    );
  }
}

// --- VIEWMODEL (STATENOTIFIER) ---

class LearnerCourseViewModel extends StateNotifier<LearnerCourseState> {
  final CourseService _courseService;
  
  // 🔑 FIX 1: Removed _unlockedCourseIds dependency from constructor
  LearnerCourseViewModel(this._courseService) : super(LearnerCourseState()) {
    _listenToAllCourses();
  }

  // Stream Listener for all courses (Removed mock enrollment initialization)
  void _listenToAllCourses() {
    _courseService.getAllCourses().listen((courses) {
      state = state.copyWith(
        allCourses: courses,
        isLoading: false,
      );
    }).onError((error) {
       state = state.copyWith(
        errorMessage: 'Failed to fetch all courses: $error',
        isLoading: false,
       );
    });
  }
  
  // 🔑 FIX 2: Removed obsolete enrolledCoursesList getter
  // The VIEW will now calculate the enrolled list directly.

  // Logic to apply search/filter (Unchanged)
  void applyFilter({
    String? search, 
    String? category, 
    double? maxPrice, 
    double? minRating,
  }) {
    state = state.copyWith(
      searchQuery: search ?? state.searchQuery,
      selectedCategory: category ?? state.selectedCategory,
      maxPriceFilter: maxPrice ?? state.maxPriceFilter,
      minRatingFilter: minRating ?? state.minRatingFilter,
    );
  }
  
  // Method to get the filtered list (Used by Explorer Tab)
  List<CourseModel> get filteredCourses {
    List<CourseModel> courses = state.allCourses;

    // 1. Filter by Search Query
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      courses = courses.where((c) => 
        c.title.toLowerCase().contains(query) || 
        c.description.toLowerCase().contains(query)
      ).toList();
    }
    
    // 2. Filter by Category
    if (state.selectedCategory != 'All') {
      courses = courses.where((c) => c.category == state.selectedCategory).toList();
    }

    // Filter by Price
    courses = courses.where((c) => c.price <= state.maxPriceFilter).toList();

    // Filter by Rating
    courses = courses.where((c) => c.rating >= state.minRatingFilter).toList();
    
    return courses;
  }

  // Method to fetch lessons for player (Unchanged)
  Future<List<VideoLessonModel>> getLessonsForCourse(String courseId) async {
    try {
      final lessons = await _courseService.getCourseLessons(courseId).first;
      return lessons;
    } catch (e) {
      debugPrint('Error fetching lessons for course $courseId: $e');
      return [];
    }
  }
}

// --- RIVERPOD PROVIDER (ALTERED) ---

final learnerCourseViewModelProvider =
    StateNotifierProvider<LearnerCourseViewModel, LearnerCourseState>((ref) {
  final courseService = ref.watch(courseServiceProvider);
  // 🔑 FIX 3: Removed watching the enrollmentProvider here
  
  return LearnerCourseViewModel(courseService);
});