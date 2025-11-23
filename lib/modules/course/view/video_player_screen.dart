import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../model/video_lesson_model.dart';
import '../viewmodel/progress_provider.dart';

class VideoPlayerScreen extends ConsumerStatefulWidget {
  final VideoLessonModel lesson;

  const VideoPlayerScreen({super.key, required this.lesson});

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isCompleted = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.network(
        widget.lesson.storageUrl,
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true, // smoother playback
        ),
      );

      // SAFELY initialize (reduces freeze issues)
      await _controller.initialize();

      if (!mounted) return;

      setState(() => _isInitializing = false);

      _controller.play();

      // AUTO COMPLETE LISTENER
      _controller.addListener(() {
        if (_controller.value.position >= _controller.value.duration &&
            !_isCompleted) {
          _markComplete();
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading video: $e")),
        );
      }
    }
  }

  void _markComplete() {
    if (_isCompleted) return;

    _isCompleted = true;
    ref.read(progressProvider.notifier).completeLesson(widget.lesson.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lesson marked as completed!")),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.lesson.title, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.green),
            onPressed: _markComplete,
          ),
        ],
      ),
      body: Center(
        child: _isInitializing
            ? const CircularProgressIndicator(color: Colors.white)
            : _controller.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  )
                : const Text("Failed to load video",
                    style: TextStyle(color: Colors.white)),
      ),
      floatingActionButton: !_isInitializing
          ? FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
              child: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.black,
              ),
            )
          : null,
    );
  }
}
