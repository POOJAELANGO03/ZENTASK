

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 🔑 FIX 1: Correct imports for course components
import '../../../providers.dart';
import '../../auth/viewmodel/auth_state_view_model.dart';
import '../viewmodel/trainer_course_viewmodel.dart';
import '../model/course_model.dart'; // FIX: Found CourseModel
// 🔑 FIX 2: Found CourseCreationScreen (assuming it is in the same view folder)
import 'course_creation_screen.dart'; 
import 'trainer_profile_screen.dart'; 

class TrainerDashboardScreen extends ConsumerWidget {
  const TrainerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trainerCourseViewModelProvider);
    final userState = ref.watch(authStateViewModelProvider);
    
    // FIX 3: Use the null-aware operator '??' to safely assign a default value
    final String trainerName = userState.maybeWhen(
      data: (userModel) => userModel?.email?.split('@').first ?? 'Trainer',
      orElse: () => 'Trainer',
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('COURSEHIVE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1, 
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.black),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TrainerProfileScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () {
              ref.read(firebaseAuthServiceProvider).signOut();
            },
          ),
        ],
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // FIX 4: Correctly call the constructor for navigation
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CourseCreationScreen())); 
        },
        label: const Text('New Course', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.black, 
      ),
      
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back, $trainerName!', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 20),
              
              _buildStatsCard(state.trainerCourses.length, 'Total Courses'),
              const SizedBox(height: 20),

              const Text('Your Courses', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 10),

              if (state.isLoading)
                const Center(child: CircularProgressIndicator(color: Colors.black))
              else if (state.errorMessage != null)
                Center(child: Text('Error: ${state.errorMessage}', style: const TextStyle(color: Colors.red)))
              else if (state.trainerCourses.isEmpty)
                const Center(child: Text('No courses found. Start creating one!', style: TextStyle(color: Colors.grey)))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.trainerCourses.length,
                  itemBuilder: (context, index) {
                    final course = state.trainerCourses[index];
                    return _buildCourseCard(context, course);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatsCard(int count, String title) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, color: Colors.black)),
          const SizedBox(height: 5),
          Text(count.toString(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.black)),
        ],
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, CourseModel course) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.black)),
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        leading: const Icon(Icons.view_list_sharp, color: Colors.black),
        title: Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        subtitle: Text('${course.category} | ${course.lessonCount} Lessons', style: TextStyle(color: Colors.grey.shade700)),
        trailing: Text('\$${course.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
        onTap: () {
          // TODO: Navigate to Edit/Manage Course Screen
        },
      ),
    );
  }
}