import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers.dart';
import '../../auth/viewmodel/auth_state_view_model.dart';
import '../viewmodel/learner_course_viewmodel.dart';
import '../model/course_model.dart';
import 'course_detail_screen.dart';
import 'video_player_screen.dart';
import '../viewmodel/progress_provider.dart';
import '../viewmodel/enrollment_provider.dart';
import '../model/video_lesson_model.dart';
import 'learner_profile_screen.dart';

// THEME (same as trainer)
const Color primaryColor = Color(0xFF9ECAD6);
const Color backgroundColor = Color(0xFFE9E3DF);

// ===============================================================
// 1. WRAPPER DASHBOARD WITH BOTTOM NAVIGATION
// ===============================================================

class LearnerDashboardScreen extends ConsumerStatefulWidget {
  const LearnerDashboardScreen({super.key});

  @override
  ConsumerState<LearnerDashboardScreen> createState() =>
      _LearnerDashboardScreenState();
}

class _LearnerDashboardScreenState
    extends ConsumerState<LearnerDashboardScreen> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _screens = const [
      LearnerCourseExplorerView(),
      LearnerEnrolledCoursesView(),
      LearnerProfileScreen(),
    ];
  }

  void _onSearchChanged() {
    ref.read(learnerCourseViewModelProvider.notifier).applyFilter(
          search: _searchController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: _screens[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        backgroundColor: primaryColor,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey.shade700,
        type: BottomNavigationBarType.fixed,
        elevation: 5,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            label: "Explore",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books_outlined),
            label: "My Courses",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// ===============================================================
// 2. COURSE EXPLORER VIEW
// ===============================================================

class LearnerCourseExplorerView extends ConsumerWidget {
  const LearnerCourseExplorerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parent =
        context.findAncestorStateOfType<_LearnerDashboardScreenState>();
    final searchController =
        parent?._searchController ?? TextEditingController();

    final state = ref.watch(learnerCourseViewModelProvider);
    final filteredCourses =
        ref.watch(learnerCourseViewModelProvider.notifier).filteredCourses;

    final learnerName = ref.watch(authStateViewModelProvider).maybeWhen(
          data: (user) => user?.email?.split("@").first ?? "Learner",
          orElse: () => "Learner",
        );

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text(
            "COURSEHIVE",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          pinned: true,
          backgroundColor: primaryColor,
          elevation: 1,
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.black),
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => const FilterModalContent(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.black),
              onPressed: () =>
                  ref.read(firebaseAuthServiceProvider).signOut(),
            ),
          ],
        ),

        // BODY
        SliverList(
          delegate: SliverChildListDelegate([
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hello, $learnerName!",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // SEARCH BAR
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Search courses...",
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.black),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Colors.black, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Colors.black, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Colors.black, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    "Available Courses",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  if (state.isLoading)
                    const Center(
                        child: CircularProgressIndicator(color: Colors.black))
                  else if (state.errorMessage != null)
                    Center(child: Text(state.errorMessage!))
                  else if (filteredCourses.isEmpty)
                    const Center(child: Text("No courses available"))
                  else
                    ...filteredCourses
                        .map((c) => _buildCourseCard(context, c))
                ],
              ),
            )
          ]),
        )
      ],
    );
  }

  Widget _buildCourseCard(BuildContext context, CourseModel course) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: primaryColor),
      ),
      child: ListTile(
        leading: const Icon(Icons.menu_book, color: primaryColor),
        title: Text(
          course.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("${course.category} | ₹${course.price}"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CourseDetailScreen(course: course),
          ),
        ),
      ),
    );
  }
}

// ===============================================================
// 3. ENROLLED COURSES VIEW
// ===============================================================

class LearnerEnrolledCoursesView extends ConsumerWidget {
  const LearnerEnrolledCoursesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(learnerCourseViewModelProvider.notifier);

    final allCourses =
        ref.watch(learnerCourseViewModelProvider.select((s) => s.allCourses));

    final enrolledCourseIds = ref.watch(enrollmentProvider);
    final completedLessons = ref.watch(progressProvider);

    final enrolledCourses =
        allCourses.where((c) => enrolledCourseIds.contains(c.id)).toList();

    Widget buildTile(CourseModel course) {
      return FutureBuilder<List<VideoLessonModel>>(
        future: viewModel.getLessonsForCourse(course.id),
        builder: (context, snapshot) {
          final lessons = snapshot.data ?? [];
          final total = lessons.length;
          final completed =
              lessons.where((l) => completedLessons.contains(l.id)).length;
          final pending = total - completed;
          final percent = total == 0 ? 0 : ((completed / total) * 100).toInt();

          return ListTile(
            title: Text(course.title),
            subtitle: Text(
              "Completed: $completed | Pending: $pending | Total: $total | Progress: $percent%",
              style: const TextStyle(color: Colors.grey),
            ),
            trailing:
                const Icon(Icons.play_circle_fill, color: Colors.black),
            onTap: () async {
              final lessonsList =
                  await viewModel.getLessonsForCourse(course.id);
              if (lessonsList.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        VideoPlayerScreen(lesson: lessonsList.first),
                  ),
                );
              }
            },
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "My Active Courses",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: primaryColor,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: enrolledCourses.isEmpty
          ? const Center(child: Text("No enrolled courses"))
          : ListView(children: enrolledCourses.map(buildTile).toList()),
    );
  }
}

// ===============================================================
// 4. UPDATED FILTER MODAL (FINAL UI)
// ===============================================================

class FilterModalContent extends ConsumerStatefulWidget {
  const FilterModalContent({super.key});

  @override
  ConsumerState<FilterModalContent> createState() =>
      _FilterModalContentState();
}

class _FilterModalContentState extends ConsumerState<FilterModalContent> {
  late double _currentMaxPrice;
  late double _currentMinRating;

  final double _maxPriceLimit = 100000;
  final double _maxRatingLimit = 5;

  @override
  void initState() {
    super.initState();
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
      _currentMinRating = 0;
    });

    ref.read(learnerCourseViewModelProvider.notifier).applyFilter(
          maxPrice: _maxPriceLimit,
          minRating: 0,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 370,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Filter Courses",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // PRICE SLIDER
          const Text("Max Price", style: TextStyle(fontWeight: FontWeight.bold)),
          Slider(
            value: _currentMaxPrice,
            min: 0,
            max: _maxPriceLimit,
            divisions: 200,
            activeColor: Colors.black,
            onChanged: (v) => setState(() => _currentMaxPrice = v),
          ),

          const SizedBox(height: 10),

          // RATING SLIDER
          const Text("Minimum Rating",
              style: TextStyle(fontWeight: FontWeight.bold)),
          Slider(
            value: _currentMinRating,
            min: 0,
            max: _maxRatingLimit,
            divisions: 5,
            activeColor: Colors.black,
            onChanged: (v) => setState(() => _currentMinRating = v),
          ),

          const SizedBox(height: 30),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _resetFilters,
                child: const Text("Reset",
                    style: TextStyle(color: Color.fromARGB(255, 10, 10, 10), fontSize: 16)),
              ),
              ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                ),
                child: const Text(
                  "Apply Filters",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
