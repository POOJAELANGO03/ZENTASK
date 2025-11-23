import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodel/learner_profile_viewmodel.dart';

const Color primaryColor = Color(0xFF9ECAD6);
const Color backgroundColor = Color(0xFFE9E3DF);

class LearnerProfileScreen extends ConsumerStatefulWidget {
  const LearnerProfileScreen({super.key});

  @override
  ConsumerState<LearnerProfileScreen> createState() =>
      _LearnerProfileScreenState();
}

class _LearnerProfileScreenState
    extends ConsumerState<LearnerProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _specializationController;
  late TextEditingController _degreeController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(learnerProfileViewModelProvider);

    _nameController =
        TextEditingController(text: state.displayName);
    _specializationController =
        TextEditingController(text: state.specialization);
    _degreeController =
        TextEditingController(text: state.degree);
    _phoneController =
        TextEditingController(text: state.phoneNumber);
    _addressController =
        TextEditingController(text: state.address);
    _bioController =
        TextEditingController(text: state.profileDetails);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specializationController.dispose();
    _degreeController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final viewModel =
        ref.read(learnerProfileViewModelProvider.notifier);

    await viewModel.saveProfileDetails(
      displayName: _nameController.text.trim(),
      specialization: _specializationController.text.trim(),
      profileDetails: _bioController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      degree: _degreeController.text.trim(),
    );

    final state = ref.read(learnerProfileViewModelProvider);

    if (!mounted) return;

    if (state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.errorMessage!)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Profile updated successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(learnerProfileViewModelProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Edit Professional Profile',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: primaryColor,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // PROFILE IMAGE
            GestureDetector(
              onTap: () => ref
                  .read(learnerProfileViewModelProvider.notifier)
                  .pickProfileImage(),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE1DBD7),
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: primaryColor,
                        width: 2,
                      ),
                      image: _buildAvatarImage(state),
                    ),
                    child: state.selectedImageFile == null &&
                            state.profileImageUrl.isEmpty
                        ? const Icon(Icons.camera_alt_outlined,
                            color: Colors.black)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tell us about your expertise.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 20),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField(
                    controller: _nameController,
                    label: 'Full Name (Mandatory)',
                    icon: Icons.person_outline,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Name is required'
                        : null,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: _specializationController,
                    label: 'Specialization (e.g., Flutter, Marketing)',
                    icon: Icons.tag_outlined,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: _degreeController,
                    label: 'Highest Degree/Certification',
                    icon: Icons.school_outlined,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: _addressController,
                    label: 'Address',
                    icon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: _bioController,
                    label: 'Professional Details/Bio',
                    icon: Icons.description_outlined,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 30),

                  // SAVE BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          state.isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: state.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Profile',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DecorationImage? _buildAvatarImage(LearnerProfileState state) {
    if (state.selectedImageFile != null) {
      return DecorationImage(
        fit: BoxFit.cover,
        image: FileImage(state.selectedImageFile!),
      );
    }
    if (state.profileImageUrl.isNotEmpty) {
      return DecorationImage(
        fit: BoxFit.cover,
        image: NetworkImage(state.profileImageUrl),
      );
    }
    return null;
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor),
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: Colors.black),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.black),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.black),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Colors.black, width: 2),
        ),
      ),
    );
  }
}
