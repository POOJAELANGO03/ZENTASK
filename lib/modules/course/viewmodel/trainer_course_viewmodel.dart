// lib/modules/course/viewmodel/trainer_course_viewmodel.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../providers.dart';
import '../model/course_model.dart';
import '../model/video_lesson_model.dart';
import '../service/course_service.dart';
import '../../auth/viewmodel/auth_state_view_model.dart';
import '../../../core/services/cloudinary_constants.dart';
import '../../../core/services/auth_service.dart';

// -----------------------------------------------------
// STATE
// -----------------------------------------------------

class TrainerCourseState {
  final bool isLoading;
  final String? errorMessage;
  final List<CourseModel> trainerCourses;
  final String? currentCourseId;

  final String displayName;
  final String specialization;
  final String profileDetails;
  final String phoneNumber;
  final String address;
  final String degree;
  final String profileImageUrl;
  final File? selectedImageFile;

  final int totalEnrollment;
  final double totalRevenueEstimate;

  final File? selectedVideoFile;
  final double uploadProgress;

  TrainerCourseState({
    this.isLoading = false,
    this.errorMessage,
    this.trainerCourses = const [],
    this.currentCourseId,
    this.displayName = '',
    this.specialization = '',
    this.profileDetails = '',
    this.phoneNumber = '',
    this.address = '',
    this.degree = '',
    this.profileImageUrl = '',
    this.selectedImageFile,
    this.totalEnrollment = 0,
    this.totalRevenueEstimate = 0.0,
    this.selectedVideoFile,
    this.uploadProgress = 0.0,
  });

  TrainerCourseState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<CourseModel>? trainerCourses,
    String? currentCourseId,
    String? displayName,
    String? specialization,
    String? profileDetails,
    String? phoneNumber,
    String? address,
    String? degree,
    String? profileImageUrl,
    File? selectedImageFile,
    double? uploadProgress,
    int? totalEnrollment,
    double? totalRevenueEstimate,
    File? selectedVideoFile,
  }) {
    return TrainerCourseState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      trainerCourses: trainerCourses ?? this.trainerCourses,
      currentCourseId: currentCourseId ?? this.currentCourseId,
      displayName: displayName ?? this.displayName,
      specialization: specialization ?? this.specialization,
      profileDetails: profileDetails ?? this.profileDetails,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      degree: degree ?? this.degree,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      selectedImageFile: selectedImageFile ?? this.selectedImageFile,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      totalEnrollment: totalEnrollment ?? this.totalEnrollment,
      totalRevenueEstimate: totalRevenueEstimate ?? this.totalRevenueEstimate,
      selectedVideoFile: selectedVideoFile ?? this.selectedVideoFile,
    );
  }
}

// -----------------------------------------------------
// VIEWMODEL
// -----------------------------------------------------

class TrainerCourseViewModel extends StateNotifier<TrainerCourseState> {
  final CourseService _courseService;
  final AuthService _authService;
  final String? _uid;

  final ImagePicker _picker = ImagePicker();

  TrainerCourseViewModel(
      this._courseService, this._uid, this._authService)
      : super(TrainerCourseState()) {
    if (_uid != null) {
      listenToTrainerCourses(_uid!);
    }
  }

  // -----------------------------------------------------
  // PROFILE IMAGE PICKING
  // -----------------------------------------------------

  Future<void> pickProfileImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (file != null) {
      state = state.copyWith(selectedImageFile: File(file.path));
    }
  }

  // -----------------------------------------------------
  // UPLOAD PROFILE IMAGE
  // -----------------------------------------------------

  Future<String> _uploadProfileImage(File file) async {
    final req = http.MultipartRequest(
      "POST",
      Uri.parse(CloudinaryConstants.UPLOAD_URL),
    );

    req.fields['upload_preset'] = CloudinaryConstants.UPLOAD_PRESET;
    req.fields['public_id'] = "trainer_profile_${_uid}";
    req.files.add(await http.MultipartFile.fromPath("file", file.path));

    final res = await http.Response.fromStream(await req.send());

    if (res.statusCode != 200) {
      throw Exception("Cloudinary Upload Failed: ${res.body}");
    }

    return jsonDecode(res.body)['secure_url'];
  }

  // -----------------------------------------------------
  // SAVE PROFILE DETAILS
  // -----------------------------------------------------

  Future<void> saveProfileDetails({
    required String displayName,
    required String specialization,
    required String profileDetails,
    required String phoneNumber,
    required String address,
    required String degree,
  }) async {
    if (_uid == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      String? imageUrl = state.profileImageUrl;

      if (state.selectedImageFile != null) {
        imageUrl = await _uploadProfileImage(state.selectedImageFile!);
      }

      await _authService.updateProfileDetails(
        uid: _uid!,
        displayName: displayName,
        specialization: specialization,
        profileDetails: profileDetails,
        phoneNumber: phoneNumber,
        address: address,
        degree: degree,
        profileImageUrl: imageUrl,
      );

      state = state.copyWith(
        isLoading: false,
        displayName: displayName,
        specialization: specialization,
        profileDetails: profileDetails,
        phoneNumber: phoneNumber,
        address: address,
        degree: degree,
        profileImageUrl: imageUrl,
        selectedImageFile: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: "$e");
    }
  }

  // -----------------------------------------------------
  // VIDEO PICK
  // -----------------------------------------------------

  Future<void> pickVideo() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file != null) {
      state = state.copyWith(selectedVideoFile: File(file.path));
    }
  }

  // -----------------------------------------------------
  // VIDEO UPLOAD + LESSON SAVE
  // -----------------------------------------------------

  Future<void> uploadLesson({
    required String courseId,
    required String title,
    required bool isPreviewable,
  }) async {
    final file = state.selectedVideoFile;
    if (file == null) {
      state = state.copyWith(errorMessage: "Select a video file first");
      return;
    }

    state = state.copyWith(isLoading: true, uploadProgress: 0);

    try {
      final lesson = VideoLessonModel(
        id: "",
        title: title,
        description: "Uploaded Video",
        durationSeconds: 0,
        storageUrl: "",
        isPreviewable: isPreviewable,
      );

      await _courseService.uploadVideoAndAddLesson(
        courseId: courseId,
        lesson: lesson,
        videoFile: file,
        onProgress: (p) {
          state = state.copyWith(uploadProgress: p);
        },
      );

      state = state.copyWith(
        isLoading: false,
        selectedVideoFile: null,
        uploadProgress: 1.0,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        uploadProgress: 0,
        errorMessage: "$e",
      );
    }
  }

  // -----------------------------------------------------
  // DELETE COURSE
  // -----------------------------------------------------

  Future<void> deleteCourseListing(String id) async {
    state = state.copyWith(isLoading: true);

    try {
      await _courseService.deleteCourse(id);
      state = state.copyWith(
          isLoading: false,
          trainerCourses: state.trainerCourses.where((c) => c.id != id).toList());
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: "$e");
    }
  }

  // -----------------------------------------------------
  // LISTEN TO COURSES
  // -----------------------------------------------------

  void listenToTrainerCourses(String uid) {
    _courseService.getTrainerCourses(uid).listen((courses) {
      final total = _courseService.calculateTotalEnrollment(courses);

      state = state.copyWith(
        trainerCourses: courses,
        totalEnrollment: total,
      );
    });
  }

  // -----------------------------------------------------
  // UPDATE COURSE
  // -----------------------------------------------------

  Future<void> updateCourse({
    required String courseId,
    required String title,
    required String description,
    required double price,
    required String category,
  }) async {
    state = state.copyWith(isLoading: true);

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
      state = state.copyWith(isLoading: false, errorMessage: "$e");
    }
  }

  // -----------------------------------------------------
  // UI COMPATIBILITY WRAPPERS (VERY IMPORTANT)
  // -----------------------------------------------------

  // COURSE CREATION SCREEN expects this ↓↓↓
  Future<String?> createCourseListing({
    required String title,
    required String description,
    required double price,
    required String category,
  }) async {
    if (_uid == null) return null;

    final course = CourseModel(
      id: "",
      trainerUid: _uid!,
      title: title,
      description: description,
      price: price,
      category: category,
      lessonCount: 0,
    );

    final id = await _courseService.createCourse(course);

    state = state.copyWith(currentCourseId: id);
    return id;
  }

  // COURSE EDIT SCREEN uses this ↓↓↓
  Future<void> updateCourseListing({
    required String courseId,
    required String title,
    required String description,
    required double price,
    required String category,
  }) {
    return updateCourse(
      courseId: courseId,
      title: title,
      description: description,
      price: price,
      category: category,
    );
  }

  // LESSON UPLOAD SCREEN expects this ↓↓↓
  void resetUploadState() {
    state = state.copyWith(
      selectedVideoFile: null,
      uploadProgress: 0.0,
      errorMessage: null,
      isLoading: false,
    );
  }
}

// -----------------------------------------------------
// PROVIDER
// -----------------------------------------------------

final trainerCourseViewModelProvider =
    StateNotifierProvider<TrainerCourseViewModel, TrainerCourseState>((ref) {
  final courseSvc = ref.watch(courseServiceProvider);
  final authSvc = ref.watch(firebaseAuthServiceProvider) as AuthService;
  final authData = ref.watch(authStateViewModelProvider);

  final uid = authData.maybeWhen(
    data: (u) => u?.uid,
    orElse: () => null,
  );

  return TrainerCourseViewModel(courseSvc, uid, authSvc);
});
