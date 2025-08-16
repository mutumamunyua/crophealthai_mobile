// lib/screens/video_player_screen.dart

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/video_model.dart'; // Our new video model

class VideoPlayerScreen extends StatefulWidget {
  // This screen takes a Video object as a parameter
  final Video video;

  const VideoPlayerScreen({super.key, required this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  // The low-level controller for the video itself
  late VideoPlayerController _videoPlayerController;

  // The high-level controller for the Chewie UI (play button, progress bar, etc.)
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    // We start initializing the player as soon as the screen is created
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    // Create the video controller from the URL in our video object
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(widget.video.videoUrl),
    );

    // Wait for the video to initialize
    await _videoPlayerController.initialize();

    // Create the Chewie UI controller
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true, // Start playing the video immediately
      looping: false,
    );

    // Refresh the screen to show the player
    setState(() {});
  }

  @override
  void dispose() {
    // It's very important to dispose of the controllers to free up resources
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.video.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: _chewieController != null &&
            _chewieController!.videoPlayerController.value.isInitialized
        // If the controller is ready, show the Chewie player
            ? Chewie(controller: _chewieController!)
        // Otherwise, show a loading spinner
            : const CircularProgressIndicator(),
      ),
    );
  }
}