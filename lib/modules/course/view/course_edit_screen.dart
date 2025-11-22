// lib/modules/course/view/course_edit_screen.dart (FINAL RECTIFICATION)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/course_model.dart';
import '../viewmodel/trainer_course_viewmodel.dart';
// 🔑 FIX 1: This import should now succeed
import '../viewmodel/course_lesson_viewmodel.dart'; 
// 🔑 FIX 2: Import the Lesson Upload Screen (assuming it exists in the view folder)
import 'lesson_upload_screen.dart'; 

class CourseEditScreen extends ConsumerStatefulWidget {
  final CourseModel course;
  const CourseEditScreen({super.key, required this.course});

  @override
  ConsumerState<CourseEditScreen> createState() => _CourseEditScreenState();
}

class _CourseEditScreenState extends ConsumerState<CourseEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _categoryController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.course.title);
    _descriptionController = TextEditingController(text: widget.course.description);
    _priceController = TextEditingController(text: widget.course.price.toStringAsFixed(2));
    _categoryController = TextEditingController(text: widget.course.category);
  }

  void _updateCourse() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final viewModel = ref.read(trainerCourseViewModelProvider.notifier);
      
      await viewModel.updateCourseListing(
        courseId: widget.course.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.tryParse(_priceController.text) ?? 0.0,
        category: _categoryController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course updated successfully!')),
        );
        Navigator.pop(context); 
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trainerCourseViewModelProvider);
    
    // 🔑 FIX 3: This watch now resolves correctly
    final lessonsAsync = ref.watch(courseLessonsStreamProvider(widget.course.id));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Edit Course: ${widget.course.title}', style: const TextStyle(color: Colors.black)),
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
              const Text('Course Metadata', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 15),

              // Title Field
              _buildTextFormField(_titleController, 'Course Title', Icons.title),
              // ... other metadata fields (Category, Price, Description) ...
              const SizedBox(height: 15),
              _buildTextFormField(_categoryController, 'Category', Icons.category),
              const SizedBox(height: 15),
              _buildTextFormField(_priceController, 'Price (\$)', Icons.money, keyboardType: TextInputType.number),
              const SizedBox(height: 15),
              _buildTextFormField(_descriptionController, 'Detailed Description', Icons.description, maxLines: 5),
              const SizedBox(height: 40),
              
              // NEW: Lessons Display Section
              const Text('Lesson Content', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 15),

              lessonsAsync.when(
                loading: () => const Center(child: Text('Loading lessons...')),
                error: (err, stack) => Center(child: Text('Error loading lessons: $err')),
                data: (lessons) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // FIX: Display the actual count from the fetched list
                      Center(
                        child: Text('${lessons.length} Lessons Created', 
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // List all lessons
                      ...lessons.map((lesson) => ListTile(
                        leading: const Icon(Icons.videocam, color: Colors.black),
                        title: Text(lesson.title, style: const TextStyle(color: Colors.black)),
                        subtitle: Text(
                          'Duration: ${lesson.durationSeconds}s | Preview: ${lesson.isPreviewable ? 'Yes' : 'No'}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )).toList(),
                      
                      const SizedBox(height: 20),
                      
                      // Button to navigate to the upload screen for THIS course
                      OutlinedButton.icon(
                        onPressed: () {
                          // 🔑 FIX 4: Correctly call the constructor for LessonUploadScreen
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => LessonUploadScreen(courseId: widget.course.id),
                          ));
                        },
                        icon: const Icon(Icons.upload_file, color: Colors.black),
                        label: const Text('Add/Upload New Lesson', style: TextStyle(color: Colors.black)),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.black)),
                      ),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: state.isLoading ? null : _updateCourse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: state.isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Changes', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.black),
        labelStyle: const TextStyle(color: Colors.black),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black, width: 2)),
      ),
      validator: (value) => value == null || value.isEmpty ? 'Please enter the $label.' : null,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    super.dispose();
  }
}