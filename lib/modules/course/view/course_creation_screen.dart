// lib/modules/course/view/course_creation_screen.dart (ALTERED - New Theme)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodel/trainer_course_viewmodel.dart';
import 'lesson_upload_screen.dart'; 

// 🔑 New Theme Colors
const Color primaryColor = Color(0xFF9ECAD6);
const Color backgroundColor = Color(0xFFE9E3DF);

class CourseCreationScreen extends ConsumerStatefulWidget {
  const CourseCreationScreen({super.key});

  @override
  ConsumerState<CourseCreationScreen> createState() => _CourseCreationScreenState();
}

class _CourseCreationScreenState extends ConsumerState<CourseCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  
  // Local state for managing the list of lessons (metadata only, actual files handled later)
  final List<String> _lessonTitles = [];
  final TextEditingController _lessonTitleController = TextEditingController();

  void _submitCourse() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final viewModel = ref.read(trainerCourseViewModelProvider.notifier);
      
      // 1. Create the Course Listing (Steps 3 & 4)
      final courseId = await viewModel.createCourseListing(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.tryParse(_priceController.text) ?? 0.0,
        category: _categoryController.text.trim(),
      );

      // Navigate to the Lesson Upload Screen using the new courseId
      if (mounted && courseId != null) {
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course listing created! Proceeding to video upload.')),
        );
        
        // Correctly call the constructor for LessonUploadScreen
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => LessonUploadScreen(courseId: courseId)),
        );
      } else if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${ref.read(trainerCourseViewModelProvider).errorMessage}')),
        );
      }
    }
  }

  void _addLessonTitle() {
    final title = _lessonTitleController.text.trim();
    if (title.isNotEmpty) {
      setState(() {
        _lessonTitles.add(title);
        _lessonTitleController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trainerCourseViewModelProvider);

    return Scaffold(
      backgroundColor: backgroundColor, // 🔑 NEW BACKGROUND
      appBar: AppBar(
        title: const Text('New Course Creation', style: TextStyle(color: Colors.black)),
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
              const Text('1. Course Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 15),

              // Title Field
              _buildTextFormField(_titleController, 'Course Title', Icons.title),
              const SizedBox(height: 15),

              // Category Field
              _buildTextFormField(_categoryController, 'Category (e.g., Development)', Icons.category),
              const SizedBox(height: 15),

              // Price Field
              _buildTextFormField(_priceController, 'Price (\$)', Icons.money, keyboardType: TextInputType.number),
              const SizedBox(height: 15),

              // Description Field
              _buildTextFormField(_descriptionController, 'Detailed Course Description', Icons.description, maxLines: 5),
              const SizedBox(height: 30),

              const Text('2. Lesson Structure (Metadata)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 15),
              
              // Lesson Title Input and Add Button (Simplified for this form)
              Row(
                children: [
                  Expanded(
                    child: _buildTextFormField(_lessonTitleController, 'Lesson Title (Optional)', Icons.label, validator: (value) => null),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _addLessonTitle,
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor, padding: const EdgeInsets.all(12)), // 🔑 NEW BUTTON COLOR
                    child: const Icon(Icons.add, color: Color.fromARGB(255, 10, 10, 10)),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              
              // Display Lesson Titles
              if (_lessonTitles.isNotEmpty)
                ..._lessonTitles.asMap().entries.map((entry) {
                  int index = entry.key;
                  String title = entry.value;
                  return ListTile(
                    leading: Icon(Icons.videocam_outlined, color: primaryColor, size: 20), // 🔑 NEW ICON COLOR
                    title: Text('Lesson ${index + 1}: $title', style: const TextStyle(color: Colors.black)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Color.fromARGB(255, 11, 11, 11)),
                      onPressed: () {
                        setState(() {
                          _lessonTitles.removeAt(index);
                        });
                      },
                    ),
                  );
                }),

              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: state.isLoading ? null : _submitCourse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor, // 🔑 NEW PRIMARY BUTTON COLOR
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: state.isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Create & Proceed to Upload', style: TextStyle(fontSize: 16, color: Color.fromARGB(255, 8, 8, 8))),
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
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.black),
        labelStyle: const TextStyle(color: Colors.black),
        // 🔑 NEW INPUT FIELD STYLING
        fillColor: Colors.white,
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primaryColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primaryColor, width: 2)),
      ),
      validator: validator ?? (value) => value == null || value.isEmpty ? 'Please enter the $label.' : null,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _lessonTitleController.dispose();
    super.dispose();
  }
}