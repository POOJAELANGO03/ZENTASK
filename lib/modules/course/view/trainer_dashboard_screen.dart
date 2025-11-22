// lib/modules/course/view/trainer_dashboard_screen.dart (ALTERED - Black/White Bottom Navigation)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers.dart';
import '../../auth/viewmodel/auth_state_view_model.dart';
import '../viewmodel/trainer_course_viewmodel.dart';
import '../model/course_model.dart'; 
import 'course_creation_screen.dart'; 
import 'course_edit_screen.dart'; 
import 'trainer_profile_screen.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; // Import for signOut logic

// --- 1. Dashboard Wrapper (Stateful for Navigation) ---

class TrainerDashboardScreen extends ConsumerStatefulWidget {
  const TrainerDashboardScreen({super.key});

  @override
  ConsumerState<TrainerDashboardScreen> createState() => _TrainerDashboardScreenState();
}

class _TrainerDashboardScreenState extends ConsumerState<TrainerDashboardScreen> {
  int _currentIndex = 0;

  // List of screens for the Bottom Navigation Bar
  final List<Widget> _screens = [
    const TrainerDashboardView(), // Home/Course List View
    const TrainerStatsView(),     // Placeholder for Statistics/Analytics
    const TrainerProfileScreen(), // Profile View
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The overall Scaffold background is white
      backgroundColor: Colors.white,
      
      body: _screens[_currentIndex], // Display the current screen
      
      // Floating Action Button for Course Creation
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CourseCreationScreen())); 
              },
              label: const Text('New Course', style: TextStyle(color: Colors.white)),
              icon: const Icon(Icons.add, color: Colors.white),
              backgroundColor: Colors.black, // Black button
            )
          : null,
      
      // 🔑 Bottom Navigation Bar Implementation (Black and White Theme)
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        // --- B&W THEME SETTINGS ---
        backgroundColor: Colors.white, 
        selectedItemColor: Colors.black, // 🔑 ACTIVE ICON/TEXT IS BLACK
        unselectedItemColor: Colors.grey.shade500, // Inactive icon/text is gray
        type: BottomNavigationBarType.fixed, // Ensure all items are visible
        elevation: 5,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.star_outline), 
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined), 
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline), 
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// --- 2. Trainer Course List View (The original Dashboard body) ---

class TrainerDashboardView extends ConsumerWidget {
  const TrainerDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trainerCourseViewModelProvider);
    final userState = ref.watch(authStateViewModelProvider);
    
    final String trainerName = userState.maybeWhen(
      data: (userModel) => userModel?.email?.split('@').first ?? 'Trainer',
      orElse: () => 'Trainer',
    );

    return CustomScrollView(
      slivers: [
        // Custom AppBar that supports the B&W theme
        SliverAppBar(
          title: const Text('COURSEHIVE', style: TextStyle(fontWeight: FontWeight.bold)),
          pinned: true,
          backgroundColor: Colors.white,
          elevation: 1,
          actions: [
            // Logout button remains, as it's a primary action
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.black),
              onPressed: () {
                ref.read(firebaseAuthServiceProvider).signOut();
              },
            ),
          ],
        ),
        
        SliverList(
          delegate: SliverChildListDelegate([
            Padding(
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
                    ...state.trainerCourses.map((course) => _buildCourseCard(context, course)).toList(),
                ],
              ),
            ),
          ]),
        ),
      ],
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
        trailing: const Icon(Icons.edit, color: Colors.black), // Show edit icon
        onTap: () {
          // Navigate to the Course Edit Screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CourseEditScreen(course: course)),
          );
        },
      ),
    );
  }
}


// --- 3. Trainer Statistics View (Placeholder) ---

class TrainerStatsView extends StatelessWidget {
  const TrainerStatsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics & Analytics', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: Colors.white,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_outlined, size: 80, color: Colors.black),
            SizedBox(height: 20),
            Text(
              'Analytics Dashboard (Placeholder)',
              style: TextStyle(fontSize: 18, color: Colors.black),
            ),
            Text(
              'Coming soon: Detailed Course Statistics and Enrollment Rates.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}