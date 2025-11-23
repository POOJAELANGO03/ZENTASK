// lib/modules/course/view/lesson_upload_screen.dart (ALTERED - New Theme)

import 'package:flutter/material.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart'; 
import '../viewmodel/trainer_course_viewmodel.dart';
import 'dart:io';

// 🔑 New Theme Colors
const Color primaryColor = Color(0xFF9ECAD6);
const Color backgroundColor = Color(0xFFE9E3DF);

class LessonUploadScreen extends ConsumerStatefulWidget {
  final String courseId;
  const LessonUploadScreen({super.key, required this.courseId});

  @override
  ConsumerState<LessonUploadScreen> createState() => _LessonUploadScreenState();
}

class _LessonUploadScreenState extends ConsumerState<LessonUploadScreen> {
  final TextEditingController _lessonTitleController = TextEditingController();
  bool _isPreviewable = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trainerCourseViewModelProvider.notifier).resetUploadState(); 
    });
  }

  void _upload() {
    final title = _lessonTitleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a lesson title.')),
      );
      return;
    }

    ref.read(trainerCourseViewModelProvider.notifier).uploadLesson(
      courseId: widget.courseId,
      title: title,
      isPreviewable: _isPreviewable,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trainerCourseViewModelProvider);

    // Listen for successful upload or error
    ref.listen<TrainerCourseState>(trainerCourseViewModelProvider, (prev, current) {
      if (current.errorMessage != null && current.errorMessage != prev!.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(current.errorMessage!), backgroundColor: Colors.red),
        );
      }
      if (prev!.uploadProgress < 1.0 && current.uploadProgress == 1.0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lesson uploaded and saved successfully!')),
        );
        _lessonTitleController.clear();
        setState(() => _isPreviewable = false);
      }
    });

    return Scaffold(
      backgroundColor: backgroundColor, // 🔑 NEW BACKGROUND
      appBar: AppBar(
        title: const Text('Add Video Lesson', style: TextStyle(color: Colors.black)),
        backgroundColor: primaryColor, // 🔑 NEW APP BAR COLOR
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Upload to Course ID:', style: TextStyle(color: Colors.grey)),
            Text(widget.courseId, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 30),

            // 1. Lesson Title Field
            TextFormField(
              controller: _lessonTitleController,
              decoration: _buildInputDecoration('Lesson Title', Icons.label),
              enabled: !state.isLoading,
            ),
            const SizedBox(height: 20),

            // 2. Preview Checkbox
            Row(
              children: [
                Checkbox(
                  value: _isPreviewable,
                  onChanged: state.isLoading ? null : (bool? value) {
                    setState(() { _isPreviewable = value ?? false; });
                  },
                  activeColor: primaryColor, // 🔑 NEW CHECKBOX COLOR
                ),
                const Text('Allow public preview?', style: TextStyle(color: Colors.black)),
              ],
            ),
            const SizedBox(height: 20),

            // 3. File Picker Button
            OutlinedButton.icon(
              onPressed: state.isLoading ? null : () => ref.read(trainerCourseViewModelProvider.notifier).pickVideo(),
              icon: Icon(Icons.videocam_outlined, color: primaryColor), // 🔑 NEW ICON COLOR
              label: Text(
                state.selectedVideoFile == null 
                  ? 'Select Video File (MP4/MOV)'
                  : state.selectedVideoFile!.path.split('/').last,
                style: const TextStyle(color: Colors.black),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                side: BorderSide(color: primaryColor), // 🔑 NEW BORDER COLOR
              ),
            ),
            const SizedBox(height: 20),
            
            // 4. Progress Indicator
            if (state.isLoading && state.uploadProgress > 0.0)
              Column(
                children: [
                  LinearProgressIndicator(
                    value: state.uploadProgress,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor), // 🔑 NEW PROGRESS COLOR
                    minHeight: 10,
                  ),
                  const SizedBox(height: 10),
                  Text('${(state.uploadProgress * 100).toStringAsFixed(0)}% Uploading...', style: const TextStyle(color: Colors.black)),
                ],
              ),
            
            if (state.errorMessage != null && state.uploadProgress < 1.0)
              Text('Error: ${state.errorMessage}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),

            const SizedBox(height: 40),

            // 5. Upload Button
            ElevatedButton(
              onPressed: state.isLoading || state.selectedVideoFile == null ? null : _upload,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor, // 🔑 NEW PRIMARY BUTTON COLOR
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: state.isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Upload & Save Lesson', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.black),
      labelStyle: const TextStyle(color: Colors.black),
      // 🔑 NEW INPUT FIELD STYLING
      fillColor: Colors.white,
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primaryColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primaryColor, width: 2)),
    );
  }

  @override
  void dispose() {
    _lessonTitleController.dispose();
    super.dispose();
  }
}