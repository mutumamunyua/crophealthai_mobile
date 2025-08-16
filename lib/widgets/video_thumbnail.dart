// lib/widgets/video_thumbnail.dart

import 'package:flutter/material.dart';
import '../models/video_model.dart';
import '../screens/video_player_screen.dart';

class VideoThumbnail extends StatelessWidget {
  final Video video;

  const VideoThumbnail({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160, // Width of each card in the horizontal list
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.only(right: 12.0),
        child: InkWell(
          onTap: () {
            // When tapped, navigate to the video player screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VideoPlayerScreen(video: video),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Placeholder for a thumbnail image
              Container(
                height: 90,
                color: Colors.black,
                width: double.infinity,
                child: Icon(Icons.play_circle_fill, color: Colors.white.withOpacity(0.7), size: 40),
              ),
              // Video title
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  video.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}