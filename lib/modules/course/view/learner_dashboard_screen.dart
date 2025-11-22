// lib/modules/course/view/learner_dashboard_screen.dart (FINAL ALTERED CODE - Step 3 Navigation Fix)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers.dart';
import '../../auth/viewmodel/auth_state_view_model.dart';
import '../viewmodel/learner_course_viewmodel.dart';

// We use the existing model
import '../model/course_model.dart'; 
// NOTE: CourseDetailScreen and VideoPlayerScreen must be implemented next
// 🔑 FIX 1: Import the correct detail screen (assuming it exists in the view folder)
import 'course_detail_screen.dart'; 
// import 'course_edit_screen.dart'; // REMOVED temporary placeholder import


// --- 1. Dashboard Wrapper (Stateful for Navigation) ---

class LearnerDashboardScreen extends ConsumerStatefulWidget {
  const LearnerDashboardScreen({super.key});

  @override
  ConsumerState<LearnerDashboardScreen> createState() => _LearnerDashboardScreenState();
}

class _LearnerDashboardScreenState extends ConsumerState<LearnerDashboardScreen> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  // List of screens for the Bottom Navigation Bar
  final List<Widget> _screens = [
    const LearnerCourseExplorerView(), // Explore Courses (Step 2)
    const LearnerEnrolledCoursesView(), // Active/Completed Courses (Step 5)
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }
  
  void _onSearchChanged() {
    // Read method uses ref.context for context access
    ref.read(learnerCourseViewModelProvider.notifier).applyFilter(
      search: _searchController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      
      body: _screens[_currentIndex], // Display the current screen
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        // B&W THEME SETTINGS
        backgroundColor: Colors.white, 
        selectedItemColor: Colors.black, 
        unselectedItemColor: Colors.grey.shade600, 
        type: BottomNavigationBarType.fixed, 
        elevation: 5,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined), 
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books_outlined), 
            label: 'My Courses',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
}

// --- 2. Learner Explore Courses View (Step 2) ---

class LearnerCourseExplorerView extends ConsumerWidget {
  const LearnerCourseExplorerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(learnerCourseViewModelProvider);
    final filteredCourses = ref.watch(learnerCourseViewModelProvider.notifier).filteredCourses;
    
    // Determine Learner Name for greeting
    final String learnerName = ref.watch(authStateViewModelProvider).maybeWhen(
      data: (userModel) => userModel?.email?.split('@').first ?? 'Learner',
      orElse: () => 'Learner',
    );
    
    // Helper to access the state of the parent StatefulWidget for the search controller
    State<StatefulWidget>? _getContextState(BuildContext context) {
      return context.findAncestorStateOfType<_LearnerDashboardScreenState>();
    }

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text('COURSEHIVE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          pinned: true,
          backgroundColor: Colors.white,
          elevation: 1,
          actions: [
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
                  Text('Hello, $learnerName!', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 20),
                  
                  // Search/Filter Input (Using the controller from the parent StatefulWidget)
                  TextField(
                    controller: (_getContextState(context) as _LearnerDashboardScreenState)._searchController,
                    decoration: InputDecoration(
                      hintText: 'Search courses by title or description...',
                      prefixIcon: const Icon(Icons.search, color: Colors.black),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  const Text('Available Courses', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 10),

                  if (state.isLoading)
                    const Center(child: CircularProgressIndicator(color: Colors.black))
                  else if (state.errorMessage != null)
                    Center(child: Text('Error: ${state.errorMessage}', style: const TextStyle(color: Colors.red)))
                  else if (filteredCourses.isEmpty)
                    const Center(child: Text('No courses match your search criteria.', style: TextStyle(color: Colors.grey)))
                  else
                    ...filteredCourses.map((course) => _buildCourseCard(context, course)).toList(),
                ],
              ),
            ),
          ]),
        ),
      ],
    );
  }
  
  Widget _buildCourseCard(BuildContext context, CourseModel course) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.black)),
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        leading: const Icon(Icons.menu_book, color: Colors.black),
        title: Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        subtitle: Text('${course.category} | \$${course.price.toStringAsFixed(2)}', style: TextStyle(color: Colors.grey.shade700)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.black, size: 16),
        onTap: () {
          // 🔑 FIX 2: Navigate to the Course Detail Screen 
          Navigator.push(
            context,
            // Changed navigation destination to the correct CourseDetailScreen
            MaterialPageRoute(builder: (context) => CourseDetailScreen(course: course)),
          );
        },
      ),
    );
  }
}

// --- 3. Learner Enrolled Courses View (Step 5) ---

class LearnerEnrolledCoursesView extends ConsumerWidget {
  const LearnerEnrolledCoursesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(learnerCourseViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Active Courses', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: Colors.white,
      body: state.enrolledCourses.isEmpty
          ? const Center(child: Text('You are not currently enrolled in any courses.'))
          : ListView.builder(
              itemCount: state.enrolledCourses.length,
              itemBuilder: (context, index) {
                final course = state.enrolledCourses[index];
                return ListTile(
                  title: Text(course.title),
                  subtitle: const Text('Progress: 75% (Mock)', style: TextStyle(color: Colors.grey)), 
                  trailing: const Icon(Icons.play_circle_fill, color: Colors.black),
                  onTap: () {
                    // Navigate to video player
                  },
                );
              },
            ),
    );
  }
}