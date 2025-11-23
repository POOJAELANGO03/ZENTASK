// lib/modules/course/view/trainer_profile_screen.dart (FINAL CORRECTED CODE WITH NEW THEME)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers.dart'; 
import '../viewmodel/trainer_course_viewmodel.dart';

// 🔑 New Theme Colors (Re-defined for scope safety, although ideally global)
const Color primaryColor = Color(0xFF9ECAD6);
const Color backgroundColor = Color(0xFFE9E3DF);

class TrainerProfileScreen extends ConsumerStatefulWidget {
  const TrainerProfileScreen({super.key});

  @override
  ConsumerState<TrainerProfileScreen> createState() => _TrainerProfileScreenState();
}

class _TrainerProfileScreenState extends ConsumerState<TrainerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _specializationController;
  late TextEditingController _detailsController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current state values
    final state = ref.read(trainerCourseViewModelProvider);
    _specializationController = TextEditingController(text: state.specialization);
    _detailsController = TextEditingController(text: state.profileDetails);
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final viewModel = ref.read(trainerCourseViewModelProvider.notifier);
      await viewModel.saveProfileDetails(
        specialization: _specializationController.text.trim(),
        profileDetails: _detailsController.text.trim(),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile details saved successfully!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trainerCourseViewModelProvider);
    
    return Scaffold(
      backgroundColor: backgroundColor, // 🔑 NEW BACKGROUND
      appBar: AppBar(
        title: const Text('Edit Professional Profile', style: TextStyle(color: Colors.black)),
        backgroundColor: primaryColor, // 🔑 NEW APP BAR COLOR
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
              // Icon for visual appeal
              const Center(child: Icon(Icons.badge_outlined, size: 80, color: Colors.black)),
              const SizedBox(height: 20),
              
              const Text(
                'Tell us about your expertise.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black),
              ),
              const SizedBox(height: 30),

              // Specialization Field
              TextFormField(
                controller: _specializationController,
                decoration: _buildInputDecoration('Specialization (e.g., Flutter, Marketing)'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter your specialization.' : null,
              ),
              const SizedBox(height: 20),

              // Profile Details Field
              TextFormField(
                controller: _detailsController,
                maxLines: 5,
                decoration: _buildInputDecoration('Professional Details/Bio'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter your professional bio.' : null,
              ),
              const SizedBox(height: 40),

              // 1. Save Profile Button
              ElevatedButton(
                onPressed: state.isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 15), // Shared Padding
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: state.isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Profile', style: TextStyle(fontSize: 16, color: Colors.black)), // Text color changed to black for contrast
              ),
              
              const SizedBox(height: 20),

              // 2. LOGOUT BUTTON FIX: Change to ElevatedButton and align style
              ElevatedButton(
                onPressed: () {
                  ref.read(firebaseAuthServiceProvider).signOut(); 
                },
                style: ElevatedButton.styleFrom(
                  // 🔑 FIX: Use the primary color background for matching box alignment
                  backgroundColor: primaryColor, 
                  // 🔑 FIX: Ensure padding matches the Save button exactly
                  padding: const EdgeInsets.symmetric(vertical: 15), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  // To retain the red text/icon look, we use the foregroundColor property
                  foregroundColor: const Color.fromARGB(255, 9, 9, 9), 
                ),
                child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Icon(Icons.logout, color: Color.fromARGB(255, 9, 9, 9)),
                        SizedBox(width: 8),
                        Text('Logout', style: TextStyle(color: Color.fromARGB(255, 9, 9, 9), fontSize: 16)),
                    ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black),
      // 🔑 NEW INPUT FIELD STYLING
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
    super.dispose();
  }
}