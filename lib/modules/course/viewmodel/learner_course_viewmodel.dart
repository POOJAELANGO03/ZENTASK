import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers.dart';
import '../model/course_model.dart';
import '../service/course_service.dart';
import '../model/video_lesson_model.dart'; 

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
  
  LearnerCourseViewModel(this._courseService) : super(LearnerCourseState()) {
    _listenToAllCourses();
  }

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
  
  List<CourseModel> get filteredCourses {
    List<CourseModel> courses = state.allCourses;

    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      courses = courses.where((c) => 
        c.title.toLowerCase().contains(query) || 
        c.description.toLowerCase().contains(query)
      ).toList();
    }
    
    if (state.selectedCategory != 'All') {
      courses = courses.where((c) => c.category == state.selectedCategory).toList();
    }

    courses = courses.where((c) => c.price <= state.maxPriceFilter).toList();
    courses = courses.where((c) => c.rating >= state.minRatingFilter).toList();
    
    return courses;
  }

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

// --- PROVIDER ---

final learnerCourseViewModelProvider =
    StateNotifierProvider<LearnerCourseViewModel, LearnerCourseState>((ref) {
  final courseService = ref.watch(courseServiceProvider);
  return LearnerCourseViewModel(courseService);
});
