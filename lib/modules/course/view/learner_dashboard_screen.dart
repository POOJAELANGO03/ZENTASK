// lib/modules/course/view/learner_dashboard_screen.dart (FINAL CORRECTED CODE - FULL FILTER IMPLEMENTATION)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers.dart';
import '../../auth/viewmodel/auth_state_view_model.dart';
import '../viewmodel/learner_course_viewmodel.dart';
import '../model/course_model.dart'; 
import 'course_detail_screen.dart'; 
// NOTE: CourseDetailScreen and VideoPlayerScreen must be implemented next


// --- 1. Dashboard Wrapper (Stateful for Navigation) ---

class LearnerDashboardScreen extends ConsumerStatefulWidget {
  const LearnerDashboardScreen({super.key});

  @override
  ConsumerState<LearnerDashboardScreen> createState() => _LearnerDashboardScreenState();
}

class _LearnerDashboardScreenState extends ConsumerState<LearnerDashboardScreen> {
  int _currentIndex = 0;
  // Controller must be accessible by child views via helper
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

// --- 2. Learner Explore Courses View (Step 2 - FULL FILTER UI) ---

class LearnerCourseExplorerView extends ConsumerWidget {
  const LearnerCourseExplorerView({super.key});

  // Helper function signature to return the State object
  _LearnerDashboardScreenState? _getContextState(BuildContext context) {
    return context.findAncestorStateOfType<_LearnerDashboardScreenState>();
  }

  void _showFilterModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // 🔑 FIX: Builder now uses the dedicated FilterModalContent widget
      builder: (context) {
        return const FilterModalContent();
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(learnerCourseViewModelProvider);
    final filteredCourses = ref.watch(learnerCourseViewModelProvider.notifier).filteredCourses;
    
    // Determine Learner Name for greeting
    final String learnerName = ref.watch(authStateViewModelProvider).maybeWhen(
      data: (userModel) => userModel?.email?.split('@').first ?? 'Learner',
      orElse: () => 'Learner',
    );
    
    // Safely access the parent state
    final parentState = _getContextState(context);
    final TextEditingController searchController = parentState != null 
        ? parentState._searchController 
        : TextEditingController();


    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text('COURSEHIVE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          pinned: true,
          backgroundColor: Colors.white,
          elevation: 1,
          actions: [
            // 🔑 Filter Button (Triggers the modal)
            IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.black),
              onPressed: () => _showFilterModal(context, ref),
            ),
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
                  
                  // Search/Filter Input
                  TextField(
                    controller: searchController,
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
                    const Center(child: Text('No courses match your criteria.', style: TextStyle(color: Colors.grey)))
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
    return GestureDetector( 
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CourseDetailScreen(course: course)),
        );
      },
      child: Card( 
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.black)),
        margin: const EdgeInsets.only(bottom: 15),
        child: ListTile( 
          leading: const Icon(Icons.menu_book, color: Colors.black),
          title: Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          subtitle: Text('${course.category} | \$${course.price.toStringAsFixed(2)}', style: TextStyle(color: Colors.grey.shade700)),
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.black, size: 16),
        ),
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

// --- 4. Filter Modal Widget (IMPLEMENTED FOR FILTER BUTTON FUNCTIONALITY) ---

class FilterModalContent extends ConsumerStatefulWidget {
  const FilterModalContent({super.key});

  @override
  ConsumerState<FilterModalContent> createState() => _FilterModalContentState();
}

class _FilterModalContentState extends ConsumerState<FilterModalContent> {
  // Local state to hold slider values before applying filter
  late double _currentMaxPrice;
  late double _currentMinRating;
  
  // Define maximum limits
  final double _maxPriceLimit = 100000.0;
  final double _maxRatingLimit = 5.0;

  @override
  void initState() {
    super.initState();
    // Initialize local state from the ViewModel's current state
    final state = ref.read(learnerCourseViewModelProvider);
    _currentMaxPrice = state.maxPriceFilter;
    _currentMinRating = state.minRatingFilter;
  }

  void _applyFilters() {
    ref.read(learnerCourseViewModelProvider.notifier).applyFilter(
      maxPrice: _currentMaxPrice,
      minRating: _currentMinRating,
    );
    Navigator.pop(context);
  }
  
  void _resetFilters() {
    setState(() {
      _currentMaxPrice = _maxPriceLimit;
      _currentMinRating = 0.0;
    });
    // Apply reset to ViewModel immediately
    ref.read(learnerCourseViewModelProvider.notifier).applyFilter(
      maxPrice: _maxPriceLimit,
      minRating: 0.0,
    );
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Filter Courses', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(color: Colors.grey),

          // 1. Price Filter (Slider)
          const Text('Max Price', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _currentMaxPrice,
                  min: 0,
                  max: _maxPriceLimit,
                  divisions: (_maxPriceLimit / 500).round(),
                  activeColor: Colors.black,
                  inactiveColor: Colors.grey.shade300,
                  onChanged: (value) {
                    setState(() {
                      _currentMaxPrice = value;
                    });
                  },
                ),
              ),
              Text('\$${_currentMaxPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),

          // 2. Rating Filter (Slider)
          const Text('Minimum Rating', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _currentMinRating,
                  min: 0,
                  max: _maxRatingLimit,
                  divisions: 5,
                  activeColor: Colors.black,
                  inactiveColor: Colors.grey.shade300,
                  onChanged: (value) {
                    setState(() {
                      _currentMinRating = value;
                    });
                  },
                ),
              ),
              Text('${_currentMinRating.toStringAsFixed(1)} ★', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 30),

          // 3. Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _resetFilters,
                child: const Text('Reset', style: TextStyle(color: Colors.red)),
              ),
              ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                child: const Text('Apply Filters', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}