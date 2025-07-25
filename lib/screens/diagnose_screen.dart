// lib/screens/diagnose_screen.dart

import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

import 'treatment_screen.dart';
import '../config.dart';  // for backendBaseURL

// ─── SPACING CONSTANTS ─────────────────────────────────────────────────
const double kDefaultPadding     = 24.0;
const double kSmallSpacing       = 12.0;
const double kMediumSpacing      = 24.0;
const double kButtonHeight       = 50.0;
const double kImageDisplayHeight = 220.0;

class DiagnoseScreen extends StatefulWidget {
  const DiagnoseScreen({Key? key}) : super(key: key);

  @override
  State<DiagnoseScreen> createState() => _DiagnoseScreenState();
}

class _DiagnoseScreenState extends State<DiagnoseScreen> {
  Uint8List? _imageBytes;
  String? _diagnosis;
  String? _confidence;
  bool _isLoading = false;

  // ✅ CHANGED: treatment, images, agrovets & extensionWorkers now top-level in result
  String? _treatmentText;
  List<String>? _treatmentImages;
  List<dynamic>? _agrovets;
  List<dynamic>? _extensionWorkers;

  final ImagePicker _picker = ImagePicker();

  Future<Position?> _getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _pickAndSend(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    await _sendToBackend(bytes);
  }

  Future<void> _sendToBackend(Uint8List imageData) async {
    setState(() {
      _isLoading        = true;
      _imageBytes       = imageData;
      _diagnosis        = null;
      _confidence       = null;
      _treatmentText    = null;
      _treatmentImages  = null;
      _agrovets         = null;
      _extensionWorkers = null;
    });

    final uri = Uri.parse('$backendBaseURL/upload');
    final pos = await _getCurrentLocation();
    final lat = pos?.latitude.toString()  ?? '0.00';
    final lon = pos?.longitude.toString() ?? '0.00';

    final req = http.MultipartRequest('POST', uri)
      ..fields['latitude']  = lat
      ..fields['longitude'] = lon
      ..files.add(http.MultipartFile.fromBytes('files', imageData, filename: 'leaf.jpg'));

    final streamed = await req.send();
    final resp     = await http.Response.fromStream(streamed);

    if (resp.statusCode == 200) {
      final data   = jsonDecode(resp.body);
      final result = data['results'][0];

      setState(() {
        // ─── Diagnosis + confidence (unchanged) ─────────────────────
        _diagnosis  = result['prediction']?.toString() ?? 'Unknown';
        _confidence = result['confidence']?.toString()    ?? '0';

        // ✅ UPDATED: parse treatmentText directly, not nested map
        _treatmentText   = result['treatment'] as String?;

        // ✅ UPDATED: treatment_images key
        _treatmentImages = List<String>.from(result['treatment_images'] ?? []);

        // ✅ UPDATED: top-level agrovets & extension_workers
        _agrovets         = List<dynamic>.from(result['agrovets'] ?? []);
        _extensionWorkers = List<dynamic>.from(result['extension_workers'] ?? []);

        _isLoading        = false;
      });
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Server error: ${resp.statusCode}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme       = Theme.of(context);
    final primary     = theme.colorScheme.primary;
    final onPrimary   = theme.colorScheme.onPrimary;
    final secondary   = theme.colorScheme.secondary;
    final onSecondary = theme.colorScheme.onSecondary;

    final screenHeight = MediaQuery.of(context).size.height;
    final topHeight    = screenHeight * 0.4; // 40% for branding + controls

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Diagnosis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),

      body: Column(
        children: [
          // ─── Top 40%: background + camera/gallery ─────────────────
          Container(
            height: topHeight,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/bg_sunrise.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _isLoading ? null : () => _pickAndSend(ImageSource.camera),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: primary,
                        child: Icon(Icons.camera_alt, size: 32, color: onPrimary),
                      ),
                    ),
                    const SizedBox(height: kSmallSpacing),
                    Text('Take a Picture', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: kMediumSpacing),
                    GestureDetector(
                      onTap: _isLoading ? null : () => _pickAndSend(ImageSource.gallery),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: secondary,
                        child: Icon(Icons.photo_library, size: 32, color: onSecondary),
                      ),
                    ),
                    const SizedBox(height: kSmallSpacing),
                    Text('Choose from Gallery', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),

          // ─── Bottom 60%: results ──────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding,
                vertical: kDefaultPadding / 2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator()),

                  if (_imageBytes != null && !_isLoading) ...[
                    const SizedBox(height: kMediumSpacing),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _imageBytes!,
                        height: kImageDisplayHeight,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],

                  if (_diagnosis != null && !_isLoading) ...[
                    const SizedBox(height: kMediumSpacing),
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(kDefaultPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Diagnosis Result', style: theme.textTheme.headlineSmall),
                            const Divider(height: 20, thickness: 1.2),
                            Row(
                              children: [
                                Icon(Icons.biotech, color: primary),
                                const SizedBox(width: kSmallSpacing),
                                Expanded(child: Text('Disease: $_diagnosis', style: theme.textTheme.bodyMedium)),
                              ],
                            ),
                            const SizedBox(height: kSmallSpacing),
                            Row(
                              children: [
                                Icon(Icons.speed, color: Colors.orange),
                                const SizedBox(width: kSmallSpacing),
                                Expanded(child: Text('Confidence: $_confidence%', style: theme.textTheme.bodyMedium)),
                              ],
                            ),
                            const SizedBox(height: kMediumSpacing),

                            // ─── VIEW TREATMENT BUTTON ─────────────────
                            SizedBox(
                              width: double.infinity,
                              height: kButtonHeight,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TreatmentScreen(disease: _diagnosis!),
                                    ),
                                  );
                                },
                                child: const Text('View Treatment'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chat feature coming soon!')),
          );
        },
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Ask an Expert'),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}