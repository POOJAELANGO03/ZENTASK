import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Simple stats model
class AdminStatsState {
  final bool isLoading;
  final String? error;
  final int totalUsers;
  final int trainerCount;
  final int learnerCount;
  final int adminCount;
  final int totalCourses;
  final int totalEnrollments; // sum of enrolledLearners across all courses

  const AdminStatsState({
    this.isLoading = true,
    this.error,
    this.totalUsers = 0,
    this.trainerCount = 0,
    this.learnerCount = 0,
    this.adminCount = 0,
    this.totalCourses = 0,
    this.totalEnrollments = 0,
  });

  AdminStatsState copyWith({
    bool? isLoading,
    String? error,
    int? totalUsers,
    int? trainerCount,
    int? learnerCount,
    int? adminCount,
    int? totalCourses,
    int? totalEnrollments,
  }) {
    return AdminStatsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalUsers: totalUsers ?? this.totalUsers,
      trainerCount: trainerCount ?? this.trainerCount,
      learnerCount: learnerCount ?? this.learnerCount,
      adminCount: adminCount ?? this.adminCount,
      totalCourses: totalCourses ?? this.totalCourses,
      totalEnrollments: totalEnrollments ?? this.totalEnrollments,
    );
  }
}

class AdminStatsViewModel extends StateNotifier<AdminStatsState> {
  final FirebaseFirestore _firestore;

  AdminStatsViewModel(this._firestore) : super(const AdminStatsState()) {
    loadStats();
  }

  Future<void> loadStats() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // 1) Users
      final usersSnap = await _firestore.collection('users').get();
      final totalUsers = usersSnap.size;

      int trainer = 0;
      int learner = 0;
      int admin = 0;

      for (final doc in usersSnap.docs) {
        final role = (doc.data()['role'] ?? '').toString().toLowerCase();
        if (role == 'trainer') trainer++;
        if (role == 'learner') learner++;
        if (role == 'admin') admin++;
      }

      // 2) Courses
      final coursesSnap = await _firestore.collection('courses').get();
      final totalCourses = coursesSnap.size;

      int totalEnrollments = 0;
      for (final doc in coursesSnap.docs) {
        final data = doc.data();
        final enrolled = (data['enrolledLearners'] ?? 0) as int;
        totalEnrollments += enrolled;
      }

      state = state.copyWith(
        isLoading: false,
        error: null,
        totalUsers: totalUsers,
        trainerCount: trainer,
        learnerCount: learner,
        adminCount: admin,
        totalCourses: totalCourses,
        totalEnrollments: totalEnrollments,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load admin stats: $e',
      );
    }
  }
}
