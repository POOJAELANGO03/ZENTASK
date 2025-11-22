// lib/modules/course/model/video_lesson_model.dart

class VideoLessonModel {
  final String id;
  final String title;
  final String description;
  final int durationSeconds; 
  final String storageUrl; 
  final bool isPreviewable; 
  final int orderIndex; 

  VideoLessonModel({
    required this.id,
    required this.title,
    required this.description,
    required this.durationSeconds,
    required this.storageUrl,
    this.isPreviewable = false, 
    this.orderIndex = 0, 
  });

  // Factory constructor to create from Firestore Map
  factory VideoLessonModel.fromFirestore(Map<String, dynamic> data, String id) {
    return VideoLessonModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      durationSeconds: data['durationSeconds'] ?? 0,
      storageUrl: data['storageUrl'] ?? '',
      isPreviewable: data['isPreviewable'] ?? false,
      orderIndex: data['orderIndex'] ?? 0,
    );
  }

  // Convert model to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'durationSeconds': durationSeconds,
      'storageUrl': storageUrl,
      'isPreviewable': isPreviewable,
      'orderIndex': orderIndex,
    };
  }

  // copyWith method (Essential for updating URL/ID after upload)
  VideoLessonModel copyWith({
    String? id,
    String? storageUrl,
    int? durationSeconds,
  }) {
    return VideoLessonModel(
      id: id ?? this.id,
      title: this.title,
      description: this.description,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      storageUrl: storageUrl ?? this.storageUrl,
      isPreviewable: this.isPreviewable,
      orderIndex: this.orderIndex,
    );
  }
}