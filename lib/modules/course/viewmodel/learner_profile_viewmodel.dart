// lib/modules/profile/viewmodel/learner_profile_viewmodel.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../../../core/services/cloudinary_constants.dart';
import '../../../core/services/auth_service.dart';
import '../../../providers.dart';
import '../../auth/viewmodel/auth_state_view_model.dart';

class LearnerProfileState {
  final bool isLoading;
  final String? errorMessage;

  final String displayName;
  final String specialization;
  final String profileDetails;
  final String phoneNumber;
  final String address;
  final String degree;
  final String profileImageUrl;
  final File? selectedImageFile;

  const LearnerProfileState({
    this.isLoading = false,
    this.errorMessage,
    this.displayName = '',
    this.specialization = '',
    this.profileDetails = '',
    this.phoneNumber = '',
    this.address = '',
    this.degree = '',
    this.profileImageUrl = '',
    this.selectedImageFile,
  });

  LearnerProfileState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? displayName,
    String? specialization,
    String? profileDetails,
    String? phoneNumber,
    String? address,
    String? degree,
    String? profileImageUrl,
    File? selectedImageFile,
  }) {
    return LearnerProfileState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      displayName: displayName ?? this.displayName,
      specialization: specialization ?? this.specialization,
      profileDetails: profileDetails ?? this.profileDetails,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      degree: degree ?? this.degree,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      selectedImageFile: selectedImageFile ?? this.selectedImageFile,
    );
  }
}

class LearnerProfileViewModel extends StateNotifier<LearnerProfileState> {
  final AuthService _authService;
  final String? _currentLearnerUid;
  final ImagePicker _picker = ImagePicker();

  LearnerProfileViewModel(this._authService, this._currentLearnerUid)
      : super(const LearnerProfileState());

  Future<void> pickProfileImage() async {
    state = state.copyWith(errorMessage: null, selectedImageFile: null);

    try {
      final XFile? file =
          await _picker.pickImage(source: ImageSource.gallery, imageQuality: 60);

      if (file != null) {
        state = state.copyWith(selectedImageFile: File(file.path));
      }
    } catch (e) {
      state = state.copyWith(errorMessage: "Failed to pick image: $e");
    }
  }

  Future<String> _uploadProfileImage(File imageFile) async {
    final uri = Uri.parse(CloudinaryConstants.UPLOAD_URL);

    final request = http.MultipartRequest("POST", uri)
      ..fields["upload_preset"] = CloudinaryConstants.UPLOAD_PRESET
      ..fields["public_id"] = "learner_profile_${_currentLearnerUid ?? ''}"
      ..files.add(await http.MultipartFile.fromPath("file", imageFile.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception("Image Upload Failed: ${response.body}");
    }

    final Map<String, dynamic> data = jsonDecode(response.body);
    return data["secure_url"];
  }

  Future<void> saveProfileDetails({
    required String displayName,
    required String specialization,
    required String profileDetails,
    required String phoneNumber,
    required String address,
    required String degree,
  }) async {
    if (_currentLearnerUid == null) {
      state = state.copyWith(
        errorMessage: "Authentication error. Please log in again.",
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      String? imageUrl = state.profileImageUrl;

      if (state.selectedImageFile != null) {
        imageUrl = await _uploadProfileImage(state.selectedImageFile!);
      }

      // IMPORTANT FIX → use updateProfileDetails
      await _authService.updateProfileDetails(
        uid: _currentLearnerUid!,
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
        profileImageUrl: imageUrl ?? '',
        selectedImageFile: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: "Failed to save profile: $e",
      );
    }
  }
}

final learnerProfileViewModelProvider =
    StateNotifierProvider<LearnerProfileViewModel, LearnerProfileState>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider) as AuthService;
  final authData = ref.watch(authStateViewModelProvider);

  final String? learnerUid = authData.maybeWhen(
    data: (userModel) => userModel?.uid,
    orElse: () => null,
  );

  return LearnerProfileViewModel(authService, learnerUid);
});
