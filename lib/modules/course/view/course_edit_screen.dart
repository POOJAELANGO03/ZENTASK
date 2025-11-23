// lib/modules/course/view/course_edit_screen.dart (ALTERED - New Theme + Delete Button)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/course_model.dart';
import '../viewmodel/trainer_course_viewmodel.dart';
import '../viewmodel/course_lesson_viewmodel.dart'; 
import 'lesson_upload_screen.dart'; 

// 🔑 New Theme Colors
const Color primaryColor = Color(0xFF9ECAD6);
const Color backgroundColor = Color(0xFFE9E3DF);

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

  // 🔴 NEW: Confirmation + delete logic
  Future<void> _confirmAndDeleteCourse() async {
    final state = ref.read(trainerCourseViewModelProvider);

    if (state.isLoading) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Course'),
        content: const Text(
            'Are you sure you want to delete this course? All lessons will also be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    final viewModel = ref.read(trainerCourseViewModelProvider.notifier);
    await viewModel.deleteCourseListing(widget.course.id);

    final newState = ref.read(trainerCourseViewModelProvider);

    if (!mounted) return;

    if (newState.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(newState.errorMessage!)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course deleted successfully!')),
      );
      Navigator.of(context).pop(); // close edit screen
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trainerCourseViewModelProvider);
    
    final lessonsAsync = ref.watch(courseLessonsStreamProvider(widget.course.id));

    return Scaffold(
      backgroundColor: backgroundColor, // 🔑 NEW BACKGROUND
      appBar: AppBar(
        title: Text('Edit Course: ${widget.course.title}', style: const TextStyle(color: Colors.black)),
        backgroundColor: primaryColor, // 🔑 NEW APP BAR COLOR
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
              const SizedBox(height: 15),
              _buildTextFormField(_categoryController, 'Category', Icons.category),
              const SizedBox(height: 15),
              _buildTextFormField(_priceController, 'Price ', Icons.money, keyboardType: TextInputType.number),
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
                        leading: Icon(Icons.videocam, color: primaryColor), // 🔑 NEW ICON COLOR
                        title: Text(lesson.title, style: const TextStyle(color: Colors.black)),
                        subtitle: Text(
                          'Duration: ${lesson.durationSeconds}s | Preview: ${lesson.isPreviewable ? 'Yes' : 'No'}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )).toList(),
                      
                      const SizedBox(height: 20),
                      
                      // Button to navigate to the upload screen for THIS course
                      ElevatedButton.icon( // 🔑 CHANGED TO ELEVATEDBUTTON.ICON (SOLID LOOK)
                        onPressed: () {
                          // Navigate to the LessonUploadScreen to add new content
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => LessonUploadScreen(courseId: widget.course.id),
                          ));
                        },
                        icon: const Icon(Icons.upload_file, color: Color.fromARGB(255, 3, 3, 3)), // 🔑 NEW ICON COLOR
                        label: const Text('Add/Upload New Lesson', style: TextStyle(color: Color.fromARGB(255, 7, 7, 7))),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ), // 🔑 NEW BORDER COLOR
                      ),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 40),

              // Save button
              ElevatedButton(
                onPressed: state.isLoading ? null : _updateCourse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor, // 🔑 NEW PRIMARY BUTTON COLOR
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: state.isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Changes', style: TextStyle(fontSize: 16, color: Color.fromARGB(255, 7, 7, 7))),
              ),

              const SizedBox(height: 12),

              // 🔴 NEW: Delete button (separate color)
              ElevatedButton(
                onPressed: state.isLoading ? null : _confirmAndDeleteCourse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: state.isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Delete Course', style: TextStyle(fontSize: 16, color: Color.fromARGB(255, 9, 9, 9))),
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
        // 🔑 FIX 1: Apply primaryColor to the prefix icon
        prefixIcon: Icon(icon, color: const Color.fromARGB(255, 9, 9, 9)), 
        labelStyle: const TextStyle(color: Colors.black),
        
        fillColor: Colors.white,
        filled: true,
        
        // 🔑 FIX 2: Border color set to primaryColor
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), 
            borderSide: const BorderSide(color: Color.fromARGB(255, 9, 9, 9))
        ),
        
        // 🔑 FIX 3: Focused Border color set to primaryColor
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), 
            borderSide: const BorderSide(color: Color.fromARGB(255, 9, 9, 9), width: 2)
        ),
        
        // 🔑 FIX 4: Ensure UN-FOCUSED border is visible
        enabledBorder: OutlineInputBorder( 
            borderRadius: BorderRadius.circular(10), 
            borderSide: const BorderSide(color: Color.fromARGB(255, 10, 10, 10), width: 1)
        ),
        
      ),
      // ... validator
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
