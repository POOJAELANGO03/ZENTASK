// lib/modules/course/view/trainer_dashboard_screen.dart (FINAL INTEGRATED CODE)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers.dart';
import '../../auth/viewmodel/auth_state_view_model.dart';
import '../viewmodel/trainer_course_viewmodel.dart';
import '../model/course_model.dart'; 
import 'course_creation_screen.dart'; 
import 'course_edit_screen.dart'; 
import 'trainer_profile_screen.dart'; 

// --- 1. Dashboard Wrapper (Stateful for Navigation) ---

class TrainerDashboardScreen extends ConsumerStatefulWidget {
  const TrainerDashboardScreen({super.key});

  @override
  ConsumerState<TrainerDashboardScreen> createState() => _TrainerDashboardScreenState();
}

class _TrainerDashboardScreenState extends ConsumerState<TrainerDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // List of screens for the Bottom Navigation Bar
    final List<Widget> _screens = [
      const TrainerDashboardView(), 
      const TrainerStatsView(),     
      const TrainerProfileViewWrapper(), 
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      
      body: _screens[_currentIndex], 
      
      // Floating Action Button
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CourseCreationScreen())); 
              },
              label: const Text('New Course', style: TextStyle(color: Colors.black)), 
              icon: const Icon(Icons.add, color: Colors.black), 
              backgroundColor: Colors.white, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.black, width: 1.5)), 
            )
          : null,
      
      // Bottom Navigation Bar Implementation (White Background)
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.white, 
        selectedItemColor: Colors.black, 
        unselectedItemColor: Colors.grey.shade600, 
        type: BottomNavigationBarType.fixed, 
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

// Wrapper for Profile Screen
class TrainerProfileViewWrapper extends StatelessWidget {
  const TrainerProfileViewWrapper({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const TrainerProfileScreen(); 
  }
}


// --- 2. Trainer Course List View (Home Tab) ---

class TrainerDashboardView extends ConsumerWidget {
  const TrainerDashboardView({super.key}); 

  // Helper methods for Home Tab (defined here for scope)
  Widget _buildStatsCard(int count, String title) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
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
        trailing: const Icon(Icons.edit, color: Colors.black), 
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CourseEditScreen(course: course)),
          );
        },
      ),
    );
  }


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
        SliverAppBar(
          title: const Text('COURSEHIVE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          pinned: true,
          backgroundColor: Colors.white,
          elevation: 1,
          actions: const [
            // Logout button is intentionally absent from App Bar
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
          ]),
        ),
      ],
    );
  }
}


// --- 3. Trainer Statistics View (Stats Tab) ---

class TrainerStatsView extends ConsumerWidget {
  const TrainerStatsView({super.key});
  
  // Helper methods defined locally (must be done in the full file)
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50, 
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, color: Colors.black)),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.black)),
            ],
          ),
          Icon(icon, size: 40, color: color),
        ],
      ),
    );
  }

  Widget _buildCoursePerformanceBar({
    required CourseModel course,
    required int enrollment,
    required double completionRate,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(course.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Enrollment: $enrollment', style: TextStyle(color: Colors.grey.shade700)),
              Text('${(completionRate * 100).toStringAsFixed(0)}% Avg. Completion', style: TextStyle(color: Colors.grey.shade800)), 
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: completionRate,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(color), 
            minHeight: 10,
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trainerCourseViewModelProvider);
    
    // 🔑 Neutral Accent Color for B&W compliance
    const Color neutralAccent = Colors.black; 
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics & Analytics', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white, 
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black), 
      ),
      backgroundColor: Colors.white,
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Key Performance Indicators', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 20),
                  
                  // 1. Total Enrollment Card
                  _buildStatCard(
                    title: 'Total Enrollments',
                    value: state.totalEnrollment.toString(),
                    icon: Icons.group_add_outlined,
                    color: neutralAccent, 
                  ),
                  const SizedBox(height: 15),

                  // 2. Total Courses Card
                   _buildStatCard(
                    title: 'Active Courses',
                    value: state.trainerCourses.length.toString(),
                    icon: Icons.view_list_sharp,
                    color: Colors.black, 
                  ),
                  const SizedBox(height: 40),

                  const Text('Course Performance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 15),
                  
                  // 3. Performance List
                  if (state.trainerCourses.isEmpty)
                    const Center(child: Text('Create courses to see performance data.'))
                  else
                    ...state.trainerCourses.map((course) {
                      final double completionRate = course.enrolledLearners > 0 ? 0.75 : 0.0;
                      
                      return _buildCoursePerformanceBar(
                        course: course,
                        enrollment: course.enrolledLearners,
                        completionRate: completionRate,
                        color: neutralAccent,
                      );
                    }).toList(),
                ],
              ),
            ),
    );
  }
}