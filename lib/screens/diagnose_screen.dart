// lib/screens/diagnose_screen.dart

import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import 'treatment_screen.dart';
import 'phone_registration_screen.dart';
import '../config.dart';

// ─── SPACING CONSTANTS ─────────────────────────────────────────────────
const double kDefaultPadding = 24.0;
const double kSmallSpacing = 12.0;
const double kMediumSpacing = 24.0;
const double kButtonHeight = 50.0;
const double kImageDisplayHeight = 220.0;

class DiagnoseScreen extends StatefulWidget {
  const DiagnoseScreen({Key? key}) : super(key: key);

  @override
  State<DiagnoseScreen> createState() => _DiagnoseScreenState();
}

class _DiagnoseScreenState extends State<DiagnoseScreen> {
  Uint8List? _imageBytes;
  bool _isLoading = false;
  String _processingMessage = '';

  // State for successful diagnosis result
  String? _diagnosis;
  String? _confidence;

  // ✅ FIX: Changed to `dynamic` to correctly handle String or List from backend.
  dynamic _treatmentData;

  List<String>? _treatmentImages;
  List<dynamic>? _agrovets;
  List<dynamic>? _extensionWorkers;

  // State for fallback when image quality is poor
  List<dynamic>? _fallbackWorkers;

  final ImagePicker _picker = ImagePicker();

  // Helper to clear all previous results and states
  void _resetState() {
    setState(() {
      _isLoading = false;
      _imageBytes = null;
      _processingMessage = '';
      _diagnosis = null;
      _confidence = null;
      _treatmentData = null; // Changed from _treatmentText
      _treatmentImages = null;
      _agrovets = null;
      _extensionWorkers = null;
      _fallbackWorkers = null;
    });
  }

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

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
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const PhoneRegistrationScreen()),
            (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> _pickAndProcess(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();

    setState(() {
      _resetState();
      _isLoading = true;
      _imageBytes = bytes;
      _processingMessage = 'Connecting to server...';
    });

    await _connectToSSE(bytes);
  }

  Future<void> _connectToSSE(Uint8List imageData) async {
    final pos = await _getCurrentLocation();
    final lat = pos?.latitude.toString()  ?? '0.00';
    final lon = pos?.longitude.toString() ?? '0.00';

    final uri = Uri.parse('$backendBaseURL/upload-sse');
    var request = http.MultipartRequest('POST', uri)
      ..fields['latitude']  = lat
      ..fields['longitude'] = lon
      ..files.add(http.MultipartFile.fromBytes('files', imageData, filename: 'leaf.jpg'));

    final client = http.Client();
    try {
      final response = await client.send(request);

      response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((event) {
        if (event.startsWith('data:')) {
          final dataString = event.substring(5).trim();
          if (dataString.isEmpty) return;
          final data = jsonDecode(dataString) as Map<String, dynamic>;

          final step = data['step'] as String?;

          setState(() {
            _processingMessage = data['message'] as String? ?? _processingMessage;
          });

          if (step == 'result') {
            final result = data['result'] as Map<String, dynamic>;
            setState(() {
              _diagnosis = result['disease'] as String?;
              _confidence = (result['confidence'] as num?)?.toStringAsFixed(2);
              _isLoading = false;
            });
            _fetchFullTreatment(_diagnosis!);

          } else if (step == 'fallback') {
            setState(() {
              _fallbackWorkers = data['workers'] as List<dynamic>?;
              _isLoading = false;
            });
          } else if (step == 'complete' || step == 'error') {
            if (_diagnosis == null && _fallbackWorkers == null) {
              setState(() {
                _isLoading = false;
                _processingMessage = data['error'] ?? 'An unknown error occurred.';
              });
            }
          }
        }
      }, onDone: () {
        client.close();
      }, onError: (error) {
        setState(() {
          _isLoading = false;
          _processingMessage = 'Failed to connect: $error';
        });
        client.close();
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _processingMessage = 'An error occurred: $e';
      });
      client.close();
    }
  }

  Future<void> _fetchFullTreatment(String diseaseName) async {
    try {
      final pos = await _getCurrentLocation();
      final lat = pos?.latitude.toString() ?? '0.0';
      final lon = pos?.longitude.toString() ?? '0.0';

      final uri = Uri.parse('$backendBaseURL/utils/treatments/${Uri.encodeComponent(diseaseName)}?latitude=$lat&longitude=$lon');
      final resp = await http.get(uri);

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() {
          // ✅ FIX: Assign the raw `treatment` data (String or List) to the dynamic variable.
          _treatmentData = data['treatment'];
          _treatmentImages = List<String>.from(data['treatment_images'] ?? []);
          _agrovets = List<dynamic>.from(data['agrovets'] ?? []);
          _extensionWorkers = List<dynamic>.from(data['extension_workers'] ?? []);
        });
      } else {
        throw Exception('Failed to load treatment details');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not load treatment: ${e.toString()}'))
        );
      }
    }
  }

  Future<void> _dial(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Diagnosis'),
        actions: [ IconButton(icon: const Icon(Icons.logout), onPressed: _logout) ],
      ),
      body: Column(
        children: [
          if (!_isLoading && _diagnosis == null && _fallbackWorkers == null)
            _buildPickerControls(theme),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(kDefaultPadding),
              child: _buildContentArea(theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerControls(ThemeData theme) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(image: AssetImage('assets/bg_sunrise.jpeg'), fit: BoxFit.cover),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => _pickAndProcess(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take a Picture'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            ),
            const SizedBox(height: kMediumSpacing),
            ElevatedButton.icon(
              onPressed: () => _pickAndProcess(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Choose from Gallery'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentArea(ThemeData theme) {
    if (_imageBytes == null) {
      return const Center(child: Text('Please select an image to diagnose.'));
    }
    if (_isLoading) {
      return Column(
        children: [
          Image.memory(_imageBytes!, height: kImageDisplayHeight, fit: BoxFit.cover, width: double.infinity),
          const SizedBox(height: kMediumSpacing),
          const CircularProgressIndicator(),
          const SizedBox(height: kSmallSpacing),
          Text(_processingMessage, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
        ],
      );
    }
    if (_fallbackWorkers != null) {
      return _buildFallbackUI(theme);
    }
    if (_diagnosis != null) {
      return _buildSuccessUI(theme);
    }
    return Center(child: Text(_processingMessage, style: TextStyle(color: theme.colorScheme.error)));
  }

  Widget _buildSuccessUI(ThemeData theme) {
    return Column(
      children: [
        Image.memory(_imageBytes!, height: kImageDisplayHeight, fit: BoxFit.cover, width: double.infinity),
        const SizedBox(height: kMediumSpacing),
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Diagnosis Result', style: theme.textTheme.headlineSmall),
                const Divider(),
                Text('Disease: $_diagnosis', style: theme.textTheme.titleMedium),
                Text('Confidence: $_confidence%', style: theme.textTheme.titleMedium),
                const SizedBox(height: kMediumSpacing),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TreatmentScreen(
                          disease: _diagnosis!,
                          // ✅ FIX: Pass the dynamic `_treatmentData` to the correct parameter.
                          treatmentData: _treatmentData,
                          imageUrls: _treatmentImages,
                          agrovets: _agrovets,
                          extensionWorkers: _extensionWorkers,
                        ),
                      ),
                    );
                  },
                  child: const Text('View Full Treatment'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackUI(ThemeData theme) {
    return Column(
      children: [
        Image.memory(_imageBytes!, height: kImageDisplayHeight, fit: BoxFit.cover, width: double.infinity),
        const SizedBox(height: kMediumSpacing),
        Card(
          elevation: 4,
          color: Colors.amber.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 40),
                const SizedBox(height: kSmallSpacing),
                Text('Image Quality Too Low', style: theme.textTheme.headlineSmall),
                const SizedBox(height: kSmallSpacing),
                Text(_processingMessage, textAlign: TextAlign.center),
                const SizedBox(height: kMediumSpacing),
                const Text('Please try another image or contact a nearby expert for help:', textAlign: TextAlign.center),
                const SizedBox(height: kMediumSpacing),
                ..._fallbackWorkers!.map((w) => Card(
                  child: ListTile(
                    title: Text('${w['first_name'] ?? ''} ${w['last_name'] ?? ''}'),
                    subtitle: Text('${w['town']}, ${w['county']}'),
                    trailing: IconButton(
                      icon: Icon(Icons.phone, color: theme.primaryColor),
                      onPressed: () => _dial(w['contact'] as String?),
                    ),
                  ),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
