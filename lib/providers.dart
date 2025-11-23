import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/auth_service.dart'; 
import 'modules/course/service/course_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'modules/admin/viewmodel/admin_stats_viewmodel.dart';

final firebaseAuthServiceProvider = Provider<AuthService>((ref) => AuthService());

final courseServiceProvider = Provider<CourseService>((ref) => CourseService());

final adminStatsViewModelProvider =
    StateNotifierProvider<AdminStatsViewModel, AdminStatsState>((ref) {
  final firestore = FirebaseFirestore.instance;
  return AdminStatsViewModel(firestore);
});
