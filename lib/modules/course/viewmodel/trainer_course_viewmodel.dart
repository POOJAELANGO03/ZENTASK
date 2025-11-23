// lib/modules/course/viewmodel/trainer_course_viewmodel.dart (FINAL CORRECTED CODE)

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


// --- STATE DEFINITION (FIXED: All Profile Fields Present) ---

class TrainerCourseState {
  final bool isLoading;
  final String? errorMessage;
  final List<CourseModel> trainerCourses; 
  final String? currentCourseId; 
  
  // Profile Details
  final String displayName;
  final String specialization; 
  final String profileDetails; 
  final String phoneNumber;
  final String address;
  final String degree;
  final String profileImageUrl;
  final File? selectedImageFile; 
  
  // Video Upload Fields
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

  // 🔑 FIX: Corrected copyWith method signature and body to include ALL parameters
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
    File? selectedVideoFile, // 🔑 FIX: Corrected video file parameter
  }) {
    String? finalErrorMessage = errorMessage ?? this.errorMessage;
    if (isLoading == false && (uploadProgress == 1.0 || errorMessage == null)) {
        finalErrorMessage = null;
    }

    return TrainerCourseState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: finalErrorMessage,
      trainerCourses: trainerCourses ?? this.trainerCourses,
      currentCourseId: currentCourseId,
      displayName: displayName ?? this.displayName,
      specialization: specialization ?? this.specialization,
      profileDetails: profileDetails ?? this.profileDetails,
      // Assigning new profile fields
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      degree: degree ?? this.degree,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      selectedImageFile: selectedImageFile ?? this.selectedImageFile, 
      uploadProgress: uploadProgress ?? this.uploadProgress,
      totalEnrollment: totalEnrollment ?? this.totalEnrollment,
      totalRevenueEstimate: totalRevenueEstimate ?? this.totalRevenueEstimate,
      // 🔑 FIX: Correctly assigning selectedVideoFile
      selectedVideoFile: selectedVideoFile ?? this.selectedVideoFile, 
    );
  }
}

// --- VIEWMODEL (STATENOTIFIER) ---

class TrainerCourseViewModel extends StateNotifier<TrainerCourseState> {
  final CourseService _courseService;
  final AuthService _authService; 
  final String? _currentTrainerUid;
  final ImagePicker _picker = ImagePicker(); 

  TrainerCourseViewModel(this._courseService, this._currentTrainerUid, this._authService) : super(TrainerCourseState()) {
    if (_currentTrainerUid != null) {
      listenToTrainerCourses(_currentTrainerUid!);
      // TODO: Fetch existing profile data (phoneNumber, address, etc.) on load
    }
  }
  
  // -----------------------------------------------------
  // 🔑 PROFILE MANAGEMENT (FIXED PARAMETER NAMES)
  // -----------------------------------------------------

  Future<void> saveProfileDetails({
    required String displayName,
    required String specialization,
    required String profileDetails,
    required String phoneNumber,
    required String address,
    required String degree,
  }) async {
    if (_currentTrainerUid == null) return;
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      String? imageUrl = state.profileImageUrl;

      // 1. Upload new image if selected
      if (state.selectedImageFile != null) {
        imageUrl = await _uploadProfileImage(state.selectedImageFile!);
      }

      // 2. Update Firestore document (AuthService method assumed fixed in Step 1)
      await _authService.updateProfileDetails(
        uid: _currentTrainerUid!,
        displayName: displayName,
        specialization: specialization,
        profileDetails: profileDetails,
        phoneNumber: phoneNumber,
        address: address,
        degree: degree,
        profileImageUrl: imageUrl,
      );

      // 3. Update local state
      state = state.copyWith(
        displayName: displayName,
        specialization: specialization,
        profileDetails: profileDetails,
        phoneNumber: phoneNumber,
        address: address,
        degree: degree,
        profileImageUrl: imageUrl,
        selectedImageFile: null, // Clear file after successful upload
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to save profile: $e');
    }
  }
  
  Future<void> pickProfileImage() async {
    // 🔑 FIX: Using correct parameter names
    state = state.copyWith(errorMessage: null, selectedImageFile: null); 

    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

      if (file != null) {
        state = state.copyWith(selectedImageFile: File(file.path)); // 🔑 FIX: Using correct parameter names
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to pick image: $e');
    }
  }
  
  Future<String> _uploadProfileImage(File imageFile) async {
    final uri = Uri.parse(CloudinaryConstants.UPLOAD_URL);
    var request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = CloudinaryConstants.UPLOAD_PRESET
      ..fields['public_id'] = 'trainer_profile_${_currentTrainerUid}' 
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode != 200) {
      throw Exception('Image Upload Failed: ${response.body}');
    }

    final Map<String, dynamic> responseData = json.decode(response.body);
    return responseData['secure_url'];
  }

  // -----------------------------------------------------
  // 🔑 VIDEO UPLOAD LOGIC (FIXED PARAMETER NAMES)
  // -----------------------------------------------------
  
  Future<void> pickVideo() async {
    // 🔑 FIX: Using correct parameter names
    state = state.copyWith(errorMessage: null, selectedVideoFile: null); 

    try {
      final XFile? file = await _picker.pickVideo(source: ImageSource.gallery); 

      if (file != null) {
        state = state.copyWith(selectedVideoFile: File(file.path)); // 🔑 FIX: Using correct parameter names
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to pick video: $e');
    }
  }

  Future<void> uploadLesson({
    required String courseId,
    required String title,
    required bool isPreviewable,
  }) async {
    final file = state.selectedVideoFile;
    if (file == null) {
      state = state.copyWith(errorMessage: 'Please select a video file first.');
      return;
    }
    
    state = state.copyWith(isLoading: true, errorMessage: null, uploadProgress: 0.0);

    try {
      final newLesson = VideoLessonModel(
        id: '', 
        title: title,
        description: 'Uploaded by Trainer', 
        durationSeconds: 0, 
        storageUrl: '', 
        isPreviewable: isPreviewable,
      );
      
      await _courseService.uploadVideoAndAddLesson(
        courseId: courseId,
        lesson: newLesson,
        videoFile: file,
        onProgress: (progress) {
          state = state.copyWith(uploadProgress: progress); 
        },
      );
      
      // 🔑 FIX: Using correct parameter names
      state = state.copyWith(isLoading: false, selectedVideoFile: null, uploadProgress: 1.0, errorMessage: 'Upload Complete!');

    } catch (e) {
      state = state.copyWith(isLoading: false, uploadProgress: 0.0, errorMessage: 'Upload failed: ${e.toString()}');
    }
  }

  // -----------------------------------------------------
  // 🔑 EXISTING/RESTORED METHODS
  // -----------------------------------------------------
  
  void resetUploadState() {
     // 🔑 FIX: Using correct parameter names
     state = state.copyWith(
      selectedVideoFile: null,
      errorMessage: null,
      uploadProgress: 0.0,
      isLoading: false,
    );
  }

  void listenToTrainerCourses(String trainerUid) {
    _courseService.getTrainerCourses(trainerUid).listen((courses) {
      final int enrollment = _courseService.calculateTotalEnrollment(courses);
      
      state = state.copyWith(
          trainerCourses: courses, 
          totalEnrollment: enrollment,
      );
    }).onError((error) {
       state = state.copyWith(errorMessage: 'Failed to fetch courses: $error');
    });
  }

  Future<String?> createCourseListing({required String title, required String description, required double price, required String category}) async {
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

  Future<void> updateCourseListing({required String courseId, required String title, required String description, required double price, required String category}) async {
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

  // 🔴 NEW: Delete course listing
  Future<void> deleteCourseListing(String courseId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _courseService.deleteCourse(courseId);

      // Remove it from local list so UI updates immediately
      final updatedCourses =
          state.trainerCourses.where((c) => c.id != courseId).toList();

      state = state.copyWith(
        isLoading: false,
        trainerCourses: updatedCourses,
      );
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Failed to delete course: $e');
    }
  }
}

// --- RIVERPOD PROVIDER (Unchanged) ---

final trainerCourseViewModelProvider =
    StateNotifierProvider<TrainerCourseViewModel, TrainerCourseState>((ref) {
  final courseService = ref.watch(courseServiceProvider);
  final authService = ref.watch(firebaseAuthServiceProvider); 
  final authData = ref.watch(authStateViewModelProvider);
  
  String? trainerUid = authData.maybeWhen(
    data: (userModel) => userModel?.uid,
    orElse: () => null,
  );
  
  return TrainerCourseViewModel(courseService, trainerUid, authService as AuthService);
});
