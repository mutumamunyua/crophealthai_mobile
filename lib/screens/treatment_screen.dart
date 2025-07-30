// lib/screens/treatment_screen.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';  // defines `backendBaseURL`

class TreatmentScreen extends StatefulWidget {
  final String disease;

  const TreatmentScreen({
    Key? key,
    required this.disease,
  }) : super(key: key);

  @override
  _TreatmentScreenState createState() => _TreatmentScreenState();
}

class _TreatmentScreenState extends State<TreatmentScreen> {
  bool _isLoading = true;
  String? _treatmentText;
  List<String>? _imageUrls;
  List<Map<String, dynamic>>? _agrovets;
  List<Map<String, dynamic>>? _extensionWorkers;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _loadTreatment();
  }

  Future<void> _loadTreatment() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      // 1) Request location permission
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw 'Location permission is required to find nearby services.';
      }

      // 2) Get current position
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 3) Fetch from backend
      final encodedDisease = Uri.encodeComponent(widget.disease.trim());
      // ✅ UPDATED: ensure route matches app.py's /utils/treatments/<disease>
      final uri = Uri.parse(
        '$backendBaseURL/utils/treatments/$encodedDisease'
            '?latitude=${pos.latitude}&longitude=${pos.longitude}',
      );
      final resp = await http.get(uri);

      if (resp.statusCode != 200) {
        throw 'Server error (${resp.statusCode})';
      }

      final data = json.decode(resp.body) as Map<String, dynamic>;

      setState(() {
        _treatmentText = data['treatment'] as String?;

        _imageUrls = (data['treatment_images'] as List?)
            ?.whereType<String>()
            .toList();

        _agrovets = (data['agrovets'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        _extensionWorkers = (data['extension_workers'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _dial(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not dial $phone')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Treatment: ${widget.disease}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_errorMsg != null
          ? Center(child: Text('Error: $_errorMsg'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Images carousel
            if (_imageUrls != null && _imageUrls!.isNotEmpty) ...[
              SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imageUrls!.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _imageUrls![i],
                      fit: BoxFit.cover,
                      width: 200,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Treatment recommendation
            if (_treatmentText != null) ...[
              Text(
                'Recommendation',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(_treatmentText!),
              const SizedBox(height: 24),
            ],

            // Nearby agrovets
            if (_agrovets != null && _agrovets!.isNotEmpty) ...[
              Text(
                'Nearby Agrovets',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._agrovets!.map((a) => Card(
                child: ListTile(
                  title: Text(a['name'] ?? 'Unknown'),
                  subtitle: Text('${a['county']}, ${a['town']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.phone),
                    onPressed: () => _dial(a['contact'] as String?),
                  ),
                ),
              )),
              const SizedBox(height: 24),
            ],

            // Extension workers
            if (_extensionWorkers != null &&
                _extensionWorkers!.isNotEmpty) ...[
              Text(
                'Extension Workers',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._extensionWorkers!.map((w) => Card(
                child: ListTile(
                  title: Text(
                    '${w['first_name'] ?? ''} ${w['last_name'] ?? ''}',
                  ),
                  subtitle: Text('${w['county']}, ${w['town']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.phone),
                    onPressed: () => _dial(w['contact'] as String?),
                  ),
                ),
              )),
            ],
          ],
        ),
      )),
    );
  }
}