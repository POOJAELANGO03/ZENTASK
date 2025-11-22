// lib/modules/course/view/course_detail_screen.dart (FINAL CORRECTED STRUCTURE)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/course_model.dart';
import '../viewmodel/course_lesson_viewmodel.dart'; 
import '../viewmodel/enrollment_provider.dart'; 
import 'video_player_screen.dart'; 
import '../../../providers.dart'; 
import '../../auth/viewmodel/auth_state_view_model.dart';
import '../service/course_service.dart';


class CourseDetailScreen extends ConsumerWidget {
  final CourseModel course;
  const CourseDetailScreen({super.key, required this.course});

  // 🔑 FIX: Helper method _showAccessDialog is now correctly defined as a method of the class
  void _showAccessDialog(BuildContext context, CourseModel course, WidgetRef ref) { 
    final learnerUid = ref.read(authStateViewModelProvider).maybeWhen(
      data: (user) => user?.uid,
      orElse: () => null,
    );
    final courseService = ref.read(courseServiceProvider); 

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlock Access'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price: \$${course.price.toStringAsFixed(2)}'),
            const SizedBox(height: 10),
            const Text('Choose access method:'),
          ],
        ),
        actions: [
          // 1. Request Access Button
          TextButton(
            onPressed: () async {
              if (learnerUid != null) {
                // Log the request to Firestore
                await (courseService as CourseService).logAccessRequest(
                  courseId: course.id,
                  learnerUid: learnerUid,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Access request sent to Trainer for review.')),
                );
              } else {
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error: Must be logged in to request access.')),
                );
              }
            },
            child: const Text('Request Access', style: TextStyle(color: Colors.black)),
          ),
          
          // 2. Simulated Payment Button
          ElevatedButton(
            onPressed: () {
              // Simulates payment and grants immediate access
              ref.read(enrollmentProvider.notifier).unlockCourse(course.id);
              Navigator.pop(context); 
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Course unlocked successfully! (Simulated Payment)')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            child: const Text('Simulate Payment', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  // Helper for Course Info Chips
  Widget _buildInfoChip(IconData icon, String text) {
    return Chip(
      avatar: Icon(icon, size: 18, color: Colors.black),
      label: Text(text, style: const TextStyle(color: Colors.black)),
      backgroundColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.black)),
    );
  }
  
  // 🔑 FIX: build method is now clean and correctly implemented
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the stream of lessons for this course ID
    final lessonsAsync = ref.watch(courseLessonsStreamProvider(course.id));
    
    // Watch the set of actively enrolled course IDs
    final enrolledCourses = ref.watch(enrollmentProvider);
    // 🔑 FIX: isCourseUnlocked variable is correctly defined and scoped
    final bool isCourseUnlocked = enrolledCourses.contains(course.id); 

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(course.title, style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. Course Metadata (About the Course) ---
            const Text('About the Course', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 8),
            Text(course.description, style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
            const SizedBox(height: 20),

            // --- 2. Key Information (FIXED OVERFLOW) ---
            Wrap( 
              spacing: 10.0, 
              runSpacing: 10.0, 
              children: [
                _buildInfoChip(Icons.person, 'Trainer: Jane Doe'), // Placeholder Trainer Name
                _buildInfoChip(Icons.category, 'Category: ${course.category}'),
                _buildInfoChip(Icons.attach_money, 'Price: \$${course.price.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 40),

            // --- 3. Course Outline (Lessons & Preview) ---
            const Text('Course Outline', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 10),

            lessonsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: Colors.black)),
              error: (err, stack) => Center(child: Text('Error loading lessons: $err')),
              data: (lessons) {
                return Column(
                  children: [
                    // List all lessons
                    ...lessons.map((lesson) {
                      final isPreview = lesson.isPreviewable;
                      final isPlayable = isPreview || isCourseUnlocked; 

                      return ListTile(
                        leading: Icon(
                          isPlayable ? Icons.visibility : Icons.lock,
                          color: isPlayable ? Colors.black : Colors.grey.shade600,
                        ),
                        title: Text(lesson.title, style: const TextStyle(color: Colors.black)),
                        subtitle: Text(
                          isPlayable ? 'Available | ${lesson.durationSeconds}s' : 'Locked Content',
                          style: TextStyle(color: isPlayable ? Colors.black : Colors.grey.shade600),
                        ),
                        trailing: isPlayable 
                            ? const Icon(Icons.play_circle_outline, color: Colors.black)
                            : null,
                        onTap: isPlayable
                            ? () {
                                // Navigate to Video Player Screen
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => VideoPlayerScreen(lesson: lesson),
                                ));
                              }
                            : null, // Locked lessons are not clickable
                      );
                    }).toList(),

                    const SizedBox(height: 40),
                    
                    // Unlock Course Button (Step 4)
                    if (!isCourseUnlocked)
                      ElevatedButton(
                        onPressed: () {
                          // FIX: Call the helper function with the required parameters
                          _showAccessDialog(context, course, ref); 
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('Unlock Course for \$${course.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, color: Colors.white)),
                      )
                    else
                      const Text(
                        'Course successfully unlocked! View lessons above.', 
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}