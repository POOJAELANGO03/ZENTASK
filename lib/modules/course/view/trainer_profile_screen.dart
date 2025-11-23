// lib/modules/course/view/trainer_profile_screen.dart (FINAL CORRECTED CODE WITH NAME FIELD ORDERED FIRST)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers.dart'; 
import '../viewmodel/trainer_course_viewmodel.dart';
import 'dart:io'; 

// 🔑 New Theme Colors
const Color primaryColor = Color(0xFF9ECAD6);
const Color backgroundColor = Color(0xFFE9E3DF);

class TrainerProfileScreen extends ConsumerStatefulWidget {
  const TrainerProfileScreen({super.key});

  @override
  ConsumerState<TrainerProfileScreen> createState() => _TrainerProfileScreenState();
}

class _TrainerProfileScreenState extends ConsumerState<TrainerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  // Existing fields
  late TextEditingController _specializationController;
  late TextEditingController _detailsController;
  // NEW FIELDS
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _degreeController;
  // 🔑 NEW: Name Field Controller
  late TextEditingController _displayNameController; 


  @override
  void initState() {
    super.initState();
    final state = ref.read(trainerCourseViewModelProvider);
    _specializationController = TextEditingController(text: state.specialization);
    _detailsController = TextEditingController(text: state.profileDetails);
    _phoneController = TextEditingController(text: state.phoneNumber);
    _addressController = TextEditingController(text: state.address);
    _degreeController = TextEditingController(text: state.degree);
    // 🔑 Initialize new Name controller
    _displayNameController = TextEditingController(text: state.displayName); 
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final viewModel = ref.read(trainerCourseViewModelProvider.notifier);
      
      await viewModel.saveProfileDetails(
        specialization: _specializationController.text.trim(),
        profileDetails: _detailsController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        degree: _degreeController.text.trim(),
        displayName: _displayNameController.text.trim(), // Pass Display Name
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile details saved successfully!')),
        );
      }
    }
  }
  
  // Local flag to prevent double-tapping the image picker button
  bool _isPicking = false; 

  void _safePickImage(viewModel) async {
    if (_isPicking) return; // Prevent re-entry
    
    setState(() {
      _isPicking = true; // Disable button immediately
    });

    try {
      await viewModel.pickProfileImage();
    } finally {
      if (mounted) {
        setState(() {
          _isPicking = false; // Re-enable button
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trainerCourseViewModelProvider);
    final viewModel = ref.read(trainerCourseViewModelProvider.notifier);
    
    final bool isDisabled = state.isLoading || _isPicking; 
    
    return Scaffold(
      backgroundColor: backgroundColor, // NEW BACKGROUND
      appBar: AppBar(
        title: const Text('Edit Professional Profile', style: TextStyle(color: Colors.black)),
        backgroundColor: primaryColor, // NEW APP BAR COLOR
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🔑 Profile Image Selector
              GestureDetector(
                onTap: isDisabled ? null : () => _safePickImage(viewModel),
                child: Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade300,
                    // Check if new file selected, or if existing URL is available
                    backgroundImage: state.selectedImageFile != null
                        ? FileImage(state.selectedImageFile!) as ImageProvider
                        : (state.profileImageUrl.isNotEmpty 
                            ? NetworkImage(state.profileImageUrl) 
                            : null),
                    child: state.selectedImageFile == null && state.profileImageUrl.isEmpty
                        ? Icon(Icons.camera_alt, size: 40, color: primaryColor)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              const Text(
                'Tell us about your expertise.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black),
              ),
              const SizedBox(height: 30),

              // 🔑 1. DISPLAY NAME FIELD (MOVED TO TOP)
              TextFormField(
                controller: _displayNameController,
                decoration: _buildInputDecoration(Icons.person, 'Full Name (Mandatory)'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter your full name.' : null,
                enabled: !isDisabled,
              ),
              const SizedBox(height: 20),


              // 2. Specialization Field (Now second)
              TextFormField(
                controller: _specializationController,
                decoration: _buildInputDecoration(Icons.person_pin, 'Specialization (e.g., Flutter, Marketing)'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter your specialization.' : null,
                enabled: !isDisabled,
              ),
              const SizedBox(height: 20),

              // 3. Degree Field
              TextFormField(
                controller: _degreeController,
                decoration: _buildInputDecoration(Icons.school, 'Highest Degree/Certification'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter your degree.' : null,
                enabled: !isDisabled,
              ),
              const SizedBox(height: 20),

              // 4. Phone Number Field
              TextFormField(
                controller: _phoneController,
                decoration: _buildInputDecoration(Icons.phone, 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (value) => value == null || value.isEmpty ? 'Please enter your phone number.' : null,
                enabled: !isDisabled,
              ),
              const SizedBox(height: 20),
              
              // 5. Address Field
              TextFormField(
                controller: _addressController,
                decoration: _buildInputDecoration(Icons.location_on, 'Address'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter your address.' : null,
                enabled: !isDisabled,
              ),
              const SizedBox(height: 20),

              // 6. Professional Details Field (Bio)
              TextFormField(
                controller: _detailsController,
                maxLines: 5,
                decoration: _buildInputDecoration(Icons.description, 'Professional Details/Bio'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter your professional bio.' : null,
                enabled: !isDisabled,
              ),
              const SizedBox(height: 40),

              // 1. Save Profile Button
              ElevatedButton(
                onPressed: isDisabled ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isDisabled
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Profile', style: TextStyle(fontSize: 16, color: Colors.black)), // Black text for contrast
              ),
              
              const SizedBox(height: 20),

              // 2. LOGOUT BUTTON
              ElevatedButton(
                onPressed: () {
                  ref.read(firebaseAuthServiceProvider).signOut(); 
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor, 
                  padding: const EdgeInsets.symmetric(vertical: 15), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  foregroundColor: const Color.fromARGB(255, 15, 14, 14), 
                ),
                child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Icon(Icons.logout, color: Color.fromARGB(255, 17, 17, 17)),
                        SizedBox(width: 8),
                        Text('Logout', style: TextStyle(color: Color.fromARGB(255, 12, 12, 12), fontSize: 16)),
                    ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(IconData icon, String label) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryColor), // New icon color
      labelStyle: const TextStyle(color: Colors.black),
      fillColor: Colors.white,
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primaryColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primaryColor, width: 2)),
    );
  }
  
  @override
  void dispose() {
    _specializationController.dispose();
    _detailsController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _degreeController.dispose();
    _displayNameController.dispose(); // Dispose the new controller
    super.dispose();
  }
}