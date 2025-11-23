


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers.dart';
import '../../auth/viewmodel/auth_state_view_model.dart';
import '../viewmodel/trainer_course_viewmodel.dart';
import '../model/course_model.dart';
import 'course_creation_screen.dart';
import 'course_edit_screen.dart';
import 'trainer_profile_screen.dart';

// NEW for Access Requests
import '../service/course_service.dart';

// Theme colors
const Color primaryColor = Color(0xFF9ECAD6);
const Color backgroundColor = Color(0xFFE9E3DF);

// --------------------- MAIN DASHBOARD SCREEN -----------------------------

class TrainerDashboardScreen extends ConsumerStatefulWidget {
  const TrainerDashboardScreen({super.key});

  @override
  ConsumerState<TrainerDashboardScreen> createState() =>
      _TrainerDashboardScreenState();
}

class _TrainerDashboardScreenState
    extends ConsumerState<TrainerDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const TrainerDashboardView(),
      const TrainerStatsView(),
      const TrainerProfileViewWrapper(),
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: screens[_currentIndex],
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CourseCreationScreen()));
              },
              label:
                  const Text('New Course', style: TextStyle(color: Colors.black)),
              icon: const Icon(Icons.add, color: Colors.black),
              backgroundColor: primaryColor,
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: primaryColor,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey.shade800,
        type: BottomNavigationBarType.fixed,
        elevation: 5,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.star_outline), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined), label: 'Stats'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

// --------------------- WRAPPER -----------------------------

class TrainerProfileViewWrapper extends StatelessWidget {
  const TrainerProfileViewWrapper({super.key});

  @override
  Widget build(BuildContext context) => const TrainerProfileScreen();
}

// --------------------- HOME TAB -----------------------------

class TrainerDashboardView extends ConsumerWidget {
  const TrainerDashboardView({super.key});

  Widget _buildStatsCard(int count, String title) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 16, color: Colors.black)),
          const SizedBox(height: 5),
          Text(count.toString(),
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.black)),
        ],
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, CourseModel course) {
    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: primaryColor)),
      child: ListTile(
        leading: Icon(Icons.view_list_sharp, color: primaryColor),
        title: Text(course.title,
            style:
                const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        subtitle: Text('${course.category} | ${course.lessonCount} Lessons',
            style: TextStyle(color: Colors.grey.shade700)),
        trailing: Icon(Icons.edit, color: primaryColor),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CourseEditScreen(course: course),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trainerCourseViewModelProvider);
    final user = ref.watch(authStateViewModelProvider);

    final trainerName = user.maybeWhen(
      data: (u) => u?.email?.split('@').first ?? 'Trainer',
      orElse: () => 'Trainer',
    );

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text('COURSEHIVE',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          backgroundColor: primaryColor,
          pinned: true,
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Welcome back, $trainerName!",
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                  const SizedBox(height: 20),
                  _buildStatsCard(state.trainerCourses.length, "Total Courses"),
                  const SizedBox(height: 20),
                  const Text("Your Courses",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                  const SizedBox(height: 10),
                  if (state.isLoading)
                    const Center(
                        child: CircularProgressIndicator(color: Colors.black))
                  else if (state.errorMessage != null)
                    Center(
                        child: Text("Error: ${state.errorMessage}",
                            style: const TextStyle(color: Colors.red)))
                  else if (state.trainerCourses.isEmpty)
                    const Center(
                        child: Text("No courses found. Start creating one!",
                            style: TextStyle(color: Colors.grey)))
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.trainerCourses.length,
                      itemBuilder: (_, i) =>
                          _buildCourseCard(context, state.trainerCourses[i]),
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

// --------------------- ACCESS REQUEST CARD -----------------------------

class AccessRequestCard extends StatelessWidget {
  final AccessRequest request;
  final CourseModel? course;
  final VoidCallback onApprove;
  final VoidCallback onDecline;

  const AccessRequestCard({
    super.key,
    required this.request,
    required this.course,
    required this.onApprove,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: primaryColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Course: ${course?.title ?? request.courseId}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 4),
            Text("Learner: ${request.learnerUid}",
                style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 4),
            Text("Status: ${request.status}",
                style: TextStyle(
                  color: request.status == "Approved"
                      ? Colors.green
                      : request.status == "Declined"
                          ? Colors.red
                          : const Color.fromARGB(255, 85, 85, 83),
                )),
            if (request.status == "Pending") ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onDecline,
                    child: const Text("Decline",
                        style: TextStyle(color: Color.fromARGB(255, 12, 12, 12))),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: const Color.fromARGB(255, 14, 14, 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text("Accept"),
                  )
                ],
              )
            ]
          ],
        ),
      ),
    );
  }
}

// --------------------- STATS TAB (WITH ACCESS REQUESTS) -----------------------------

class TrainerStatsView extends ConsumerWidget {
  const TrainerStatsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trainerCourseViewModelProvider);
    final notifier =
        ref.read(trainerCourseViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Statistics & Analytics",
            style: TextStyle(color: Colors.black)),
        backgroundColor: primaryColor,
        elevation: 1,
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.black),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Key Performance Indicators",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: primaryColor, width: 2)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Total Enrollments",
                            style:
                                TextStyle(fontSize: 16, color: Colors.black)),
                        const SizedBox(height: 5),
                        Text(state.totalEnrollment.toString(),
                            style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                color: Colors.black)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: primaryColor, width: 2)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Active Courses",
                            style:
                                TextStyle(fontSize: 16, color: Colors.black)),
                        const SizedBox(height: 5),
                        Text(state.trainerCourses.length.toString(),
                            style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                color: Colors.black)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  const Text("Course Performance",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),

                  const SizedBox(height: 15),

                  if (state.trainerCourses.isEmpty)
                    const Center(child: Text("Create courses to see performance data."))
                  else
                    Column(
                      children: state.trainerCourses.map((course) {
                        final completionRate =
                            course.enrolledLearners > 0 ? 0.75 : 0.0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(course.title,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black)),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Enrollment: ${course.enrolledLearners}",
                                      style: TextStyle(
                                          color: Colors.grey.shade700)),
                                  Text("${(completionRate * 100).toStringAsFixed(0)}% Avg. Completion",
                                      style: TextStyle(
                                          color: Colors.grey.shade800)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: completionRate,
                                backgroundColor:
                                    const Color.fromARGB(255, 182, 179, 179),
                                valueColor: const AlwaysStoppedAnimation(
                                    primaryColor),
                                minHeight: 10,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                  // ---------------- ACCESS REQUEST SECTION ---------------------

                  const SizedBox(height: 40),

                  const Text("Access Requests",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                  const SizedBox(height: 10),

                  if (state.accessRequests.isEmpty)
                    const Text("No access requests yet.",
                        style: TextStyle(color: Colors.grey))
                  else
                    Column(
                      children: state.accessRequests.map((req) {
                        CourseModel? course;
                        try {
                          course = state.trainerCourses
                              .firstWhere((c) => c.id == req.courseId);
                        } catch (_) {
                          course = null;
                        }

                        return AccessRequestCard(
                          request: req,
                          course: course,
                          onApprove: () {
                            notifier.approveRequest(req);
                          },
                          onDecline: () {
                            notifier.declineRequest(req);
                          },
                        );
                      }).toList(),
                    ),

                ],
              ),
            ),
    );
  }
}



