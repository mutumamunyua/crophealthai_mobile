// lib/models/video_model.dart

class Video {
  final String title;
  final String description;
  final String videoUrl;
  final String? thumbnailUrl;

  Video({
    required this.title,
    required this.description,
    required this.videoUrl,
    this.thumbnailUrl,
  });

  // This is a factory constructor that creates a Video object from a JSON map.
  // It makes parsing the data from your API clean and safe.
  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      title: json['title'] ?? 'Untitled Video',
      description: json['description'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
    );
  }
}