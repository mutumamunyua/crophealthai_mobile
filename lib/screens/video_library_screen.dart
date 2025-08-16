// lib/screens/video_library_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import '../config.dart';
import '../models/video_model.dart';

class VideoLibraryScreen extends StatefulWidget {
  const VideoLibraryScreen({super.key});

  @override
  State<VideoLibraryScreen> createState() => _VideoLibraryScreenState();
}

class _VideoLibraryScreenState extends State<VideoLibraryScreen> {
  late Future<Map<String, List<Video>>> _videosFuture;
  String? _selectedCategory;
  Video? _selectedVideo;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _videosFuture = _fetchAndSetInitialVideo();
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<Map<String, List<Video>>> _fetchAndSetInitialVideo() async {
    final categorizedVideos = await _fetchVideos();
    if (mounted && categorizedVideos.isNotEmpty) {
      final firstCategory = categorizedVideos.keys.first;
      if (categorizedVideos[firstCategory]!.isNotEmpty) {
        final firstVideo = categorizedVideos[firstCategory]!.first;
        // Set the initial state without calling setState yet, as the FutureBuilder will handle the first build
        _selectedCategory = firstCategory;
        // We initialize the player for the first video
        await _initializePlayerForVideo(firstVideo);
      }
    }
    return categorizedVideos;
  }

  Future<Map<String, List<Video>>> _fetchVideos() async {
    final uri = Uri.parse('$backendBaseURL/videos');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data.map((category, videosJson) {
        final videosList = (videosJson as List)
            .map((videoJson) => Video.fromJson(videoJson))
            .toList();
        return MapEntry(category, videosList);
      });
    } else {
      throw Exception('Failed to load videos from the server.');
    }
  }

  Future<void> _initializePlayerForVideo(Video video) async {
    _disposePlayer(); // Dispose previous player first

    final videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(video.videoUrl));
    await videoPlayerController.initialize();

    if (mounted) {
      setState(() {
        _selectedVideo = video;
        _videoPlayerController = videoPlayerController;
        _chewieController = ChewieController(
          videoPlayerController: videoPlayerController,
          autoPlay: true,
          looping: false,
        );
      });
    }
  }

  void _onCategorySelected(String category, Map<String, List<Video>> allVideos) {
    setState(() {
      _selectedCategory = category;
      _disposePlayer();
      _selectedVideo = null; // Reset selected video

      // Select the first video of the new category
      if (allVideos[category]!.isNotEmpty) {
        _initializePlayerForVideo(allVideos[category]!.first);
      }
    });
  }

  void _disposePlayer() {
    _videoPlayerController?.pause();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      appBar: AppBar(
        title: const Text('Educational Video Library'),
      ),
      body: FutureBuilder<Map<String, List<Video>>>(
        future: _videosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No videos available.'));
          }

          final categorizedVideos = snapshot.data!;

          return Column(
            children: [
              Expanded(
                flex: 1,
                child: _buildVideoUI(categorizedVideos),
              ),
              Expanded(
                flex: 1,
                child: _buildAdPlaceholder(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVideoUI(Map<String, List<Video>> categorizedVideos) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _buildCategoryList(categorizedVideos),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 3,
          child: _buildContentPanel(categorizedVideos),
        ),
      ],
    );
  }

  Widget _buildCategoryList(Map<String, List<Video>> categorizedVideos) {
    final categories = categorizedVideos.keys.toList();
    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final isSelected = category == _selectedCategory;
        return ListTile(
          dense: true,
          title: Text(
            category,
            style: TextStyle(
              fontFamily: 'Garamond',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
            ),
          ),
          tileColor: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
          onTap: () => _onCategorySelected(category, categorizedVideos),
        );
      },
    );
  }

  Widget _buildContentPanel(Map<String, List<Video>> categorizedVideos) {
    return Center(
      child: _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
          ? Chewie(controller: _chewieController!)
          : const CircularProgressIndicator(),
    );
  }

  Widget _buildAdPlaceholder() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade600, Colors.green.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.storefront_outlined, size: 50, color: Colors.white.withOpacity(0.8)),
              const SizedBox(height: 16),
              const Text(
                "Connect with Local Partners",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Agrovets, Seeds and Expert Services; Coming Soon!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}