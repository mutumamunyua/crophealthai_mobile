// lib/screens/treatment_screen.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../widgets/contact_scroller.dart';
import 'video_library_screen.dart';

class TreatmentScreen extends StatefulWidget {
  final String disease;
  final dynamic treatmentData;
  final List<String>? imageUrls;
  final List<dynamic>? agrovets;
  final List<dynamic>? extensionWorkers;

  const TreatmentScreen({
    super.key,
    required this.disease,
    this.treatmentData,
    this.imageUrls,
    this.agrovets,
    this.extensionWorkers,
  });

  @override
  State<TreatmentScreen> createState() => _TreatmentScreenState();
}

class _TreatmentScreenState extends State<TreatmentScreen> {
  // --- STATE AND DATA FETCHING LOGIC (UNCHANGED) ---
  bool _isLoading = true;
  String? _errorMsg;
  List<String> _treatmentOptions = [];
  int _currentTreatmentIndex = 0;
  Timer? _timer;
  List<String> _imageUrls = [];
  List<Map<String, dynamic>>? _agrovets;
  List<Map<String, dynamic>>? _extensionWorkers;
  bool _noTreatmentAvailable = false;
  int _currentImageIndex = 0;
  Timer? _imageTimer;

  @override
  void initState() {
    super.initState();
    if (widget.treatmentData != null) {
      _loadDataFromWidget();
    } else {
      _fetchTreatmentFromNetwork();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _imageTimer?.cancel();
    super.dispose();
  }

  void _startImageTimer() {
    _imageTimer?.cancel();
    if (_imageUrls.length > 1) {
      _imageTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (mounted) {
          setState(() {
            _currentImageIndex = (_currentImageIndex + 1) % _imageUrls.length;
          });
        }
      });
    }
  }

  void _parseAndLoadData(
      dynamic treatmentData,
      List<dynamic>? images,
      List<dynamic>? agrovets,
      List<dynamic>? workers,
      ) {
    if (treatmentData is List) {
      _treatmentOptions = treatmentData.map((e) => e.toString()).toList();
    } else if (treatmentData is String) {
      _treatmentOptions = [treatmentData];
    } else {
      _treatmentOptions = [];
    }
    if (images != null) {
      _imageUrls = images.map((e) {
        final path = e.toString();
        if (path.startsWith('http')) return path;
        return '$backendBaseURL${path.startsWith('/') ? path : '/$path'}';
      }).toList();
    }
    _agrovets = agrovets?.map((e) => Map<String, dynamic>.from(e)).toList();
    _extensionWorkers =
        workers?.map((e) => Map<String, dynamic>.from(e)).toList();
    if (_treatmentOptions.isNotEmpty &&
        _treatmentOptions.first.contains("No treatment available")) {
      _noTreatmentAvailable = true;
    }
    _isLoading = false;
    _startTimer();
    _startImageTimer();
  }

  void _loadDataFromWidget() {
    setState(() {
      _parseAndLoadData(
        widget.treatmentData,
        widget.imageUrls,
        widget.agrovets,
        widget.extensionWorkers,
      );
    });
  }

  Future<void> _fetchTreatmentFromNetwork() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final pos = await _getCurrentLocation();
      final uri = Uri.parse(
          '$backendBaseURL/utils/treatments/${Uri.encodeComponent(widget.disease)}?latitude=${pos.latitude}&longitude=${pos.longitude}');
      final resp = await http.get(uri);
      if (resp.statusCode != 200) throw 'Server error (${resp.statusCode})';
      final data = json.decode(resp.body) as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _parseAndLoadData(
            data['treatment'],
            data['treatment_images'],
            data['agrovets'],
            data['extension_workers'],
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<Position> _getCurrentLocation() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permission is required to find nearby services.');
    }
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  void _startTimer() {
    if (_treatmentOptions.length > 1) {
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted) {
          setState(() {
            _currentTreatmentIndex =
                (_currentTreatmentIndex + 1) % _treatmentOptions.length;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      appBar: AppBar(
        title: Text('Treatment: ${widget.disease}'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMsg != null) return Center(child: Text('Error: $_errorMsg'));
    if (_noTreatmentAvailable) return _buildNoTreatmentUI();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildImageCarousel(),
          const SizedBox(height: 8),
          // 🔴 MODIFIED: Wrapped the treatment card in a Flexible widget
          // This allows it to expand and show all text without being cut off.
          Flexible(
            child: _buildTreatmentCard(),
          ),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade800,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              icon: const Icon(Icons.video_library_outlined),
              label: const Text("Open Video Library"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VideoLibraryScreen()),
                );
              },
            ),
          ),
          const Divider(height: 24),
          // This Column now holds the contact scrollers
          Column(
            children: [
              ContactScroller(
                title: 'Nearby Agrovets',
                contacts: _agrovets,
                icon: Icons.store_mall_directory,
              ),
              const SizedBox(height: 12),
              ContactScroller(
                title: 'Extension Workers',
                contacts: _extensionWorkers,
                icon: Icons.support_agent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🔴 MODIFIED: Increased height for a more prominent image
  Widget _buildImageCarousel() {
    if (_imageUrls.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 180, // Increased height
      child: Image.network(
        _imageUrls[_currentImageIndex],
        fit: BoxFit.contain,
        width: double.infinity,
        errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
      ),
    );
  }

  Widget _buildTreatmentCard() {
    final theme = Theme.of(context);
    if (_treatmentOptions.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Allows the card to wrap its content
          children: [
            Text(
              'Recommended Treatment',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 12),
            // 🔴 MODIFIED: Removed maxLines to allow text to expand
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: Text(
                _treatmentOptions[_currentTreatmentIndex],
                key: ValueKey<int>(_currentTreatmentIndex),
                style: const TextStyle(
                  fontFamily: 'Garamond',
                  fontSize: 15,
                  color: Color(0xFF003366),
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoTreatmentUI() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            elevation: 4,
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.blue.shade700, size: 40),
                  const SizedBox(height: 12),
                  Text('Unrecognized Disease',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    _treatmentOptions.isNotEmpty
                        ? _treatmentOptions.first
                        : 'No treatment available.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ContactScroller(
              title: 'Contact an Expert for Help',
              contacts: _extensionWorkers,
              icon: Icons.support_agent),
        ],
      ),
    );
  }
}