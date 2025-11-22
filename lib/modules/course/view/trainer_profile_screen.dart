// lib/modules/course/view/trainer_profile_screen.dart (FINAL CORRECTED CODE WITH LOGOUT)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers.dart'; // 🔑 Import providers for firebaseAuthServiceProvider
import '../viewmodel/trainer_course_viewmodel.dart';

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
        // Do NOT pop here, as the screen is part of the Bottom Nav Bar
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trainerCourseViewModelProvider);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Professional Profile', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
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
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: state.isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Profile', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
              
              const SizedBox(height: 20),

              // 🔑 2. LOGOUT BUTTON IMPLEMENTATION
              OutlinedButton.icon(
                onPressed: () {
                  // Calls the sign out service via Riverpod provider
                  ref.read(firebaseAuthServiceProvider).signOut(); 
                },
                icon: const Icon(Icons.logout, color: Color.fromARGB(255, 19, 19, 19)),
                label: const Text('Logout', style: TextStyle(color: Color.fromARGB(255, 13, 13, 13))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color.fromARGB(255, 11, 11, 11)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black, width: 2)),
    );
  }
  
  @override
  void dispose() {
    _specializationController.dispose();
    _detailsController.dispose();
    super.dispose();
  }
}