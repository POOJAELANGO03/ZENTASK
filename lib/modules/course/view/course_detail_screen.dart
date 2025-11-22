// lib/modules/course/view/course_detail_screen.dart (FINAL FIX - Enrollment Tracking)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/course_model.dart';
import '../viewmodel/course_lesson_viewmodel.dart'; 
// 🔑 NEW IMPORT: Enrollment Provider
import '../viewmodel/enrollment_provider.dart'; 
// NOTE: VideoPlayerScreen import required
import 'video_player_screen.dart'; 

class CourseDetailScreen extends ConsumerWidget {
  final CourseModel course;
  const CourseDetailScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the stream of lessons for this course ID
    final lessonsAsync = ref.watch(courseLessonsStreamProvider(course.id));
    // 🔑 NEW: Watch the set of actively enrolled course IDs
    final enrolledCourses = ref.watch(enrollmentProvider);
    final bool isCourseUnlocked = enrolledCourses.contains(course.id); // 🔑 Check status dynamically
    
    // Helper for Unlock Course Simulation (Step 4)
    void _showAccessDialog(BuildContext context, double price) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Simulated Payment'),
          content: Text('Confirm purchase of the course for \$${price.toStringAsFixed(2)}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.black)),
            ),
            ElevatedButton(
              onPressed: () {
                // 🔑 FIX: CALL THE NOTIFIER TO UNLOCK THE COURSE ID
                ref.read(enrollmentProvider.notifier).unlockCourse(course.id);
                Navigator.pop(context); // Close dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Course unlocked successfully! (Simulated)')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: const Text('Confirm', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
    
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
                      final isPlayable = isPreview || isCourseUnlocked; // 🔑 CHECK: Is it free or is the course unlocked?

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
                    
                    // 🔑 Unlock Course Button (Step 4)
                    if (!isCourseUnlocked)
                      ElevatedButton(
                        onPressed: () {
                          _showAccessDialog(context, course.price);
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
  
  // Helper for Course Info Chips
  Widget _buildInfoChip(IconData icon, String text) {
    return Chip(
      avatar: Icon(icon, size: 18, color: Colors.black),
      label: Text(text, style: const TextStyle(color: Colors.black)),
      backgroundColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.black)),
    );
  }
}