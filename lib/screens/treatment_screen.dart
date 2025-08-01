// lib/screens/treatment_screen.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';

// NOTE: No other screen imports are needed here, which prevents the circular dependency error.

class TreatmentScreen extends StatefulWidget {
  final String disease;
  final dynamic treatmentData;
  final List<String>? imageUrls;
  final List<dynamic>? agrovets;
  final List<dynamic>? extensionWorkers;

  const TreatmentScreen({
    Key? key,
    required this.disease,
    this.treatmentData,
    this.imageUrls,
    this.agrovets,
    this.extensionWorkers,
  }) : super(key: key);

  @override
  _TreatmentScreenState createState() => _TreatmentScreenState();
}

class _TreatmentScreenState extends State<TreatmentScreen> {
  bool _isLoading = true;
  String? _errorMsg;

  List<String> _treatmentOptions = [];
  int _currentTreatmentIndex = 0;
  Timer? _timer;

  List<String> _imageUrls = [];
  List<Map<String, dynamic>>? _agrovets;
  List<Map<String, dynamic>>? _extensionWorkers;
  bool _noTreatmentAvailable = false;

  // ADDED: fields for cycling through images
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
    _imageTimer?.cancel(); // ADDED: cancel image timer
    super.dispose();
  }

  // ADDED: start automatic image cycling every 4 seconds
  void _startImageTimer() {
    _imageTimer?.cancel();
    if (_imageUrls.length > 1) {
      _imageTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        setState(() {
          _currentImageIndex = (_currentImageIndex + 1) % _imageUrls.length;
        });
      });
    }
  }

  List<dynamic>? _extensionWorkersRaw;

  void _parseAndLoadData(
      dynamic treatmentData,
      List<dynamic>? images,
      List<dynamic>? agrovets,
      List<dynamic>? workers,
      ) {
    // existing parsing logic
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
    _extensionWorkersRaw = workers;
    _extensionWorkers = workers?.map((e) => Map<String, dynamic>.from(e)).toList();

    if (_treatmentOptions.isNotEmpty &&
        _treatmentOptions.first.contains("No treatment available")) {
      _noTreatmentAvailable = true;
    }

    _isLoading = false;
    _startTimer();          // existing rotating treatment text timer
    _startImageTimer();     // ADDED: start image cycle
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
      setState(() {
        _parseAndLoadData(
          data['treatment'],
          data['treatment_images'],
          data['agrovets'],
          data['extension_workers'],
        );
      });
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
        _isLoading = false;
      });
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
        setState(() {
          _currentTreatmentIndex =
              (_currentTreatmentIndex + 1) % _treatmentOptions.length;
        });
      });
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
    return Scaffold(
      // MODIFIED: soft light-blue background
      backgroundColor: Colors.lightBlue.shade50,
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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageCarousel(),       // MODIFIED: single cycling image
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTreatmentCard(),   // MODIFIED: styled title & text
                const SizedBox(height: 24),
                _buildContactList(
                    'Nearby Agrovets', _agrovets, Icons.store_mall_directory),
                const SizedBox(height: 24),
                _buildContactList('Extension Workers',
                    _extensionWorkers, Icons.support_agent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // MODIFIED: show only one image, cycling every 4s
  Widget _buildImageCarousel() {
    if (_imageUrls.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 220,
      color: Colors.lightBlue.shade50, // match screen bg
      child: Center(
        child: Image.network(
          _imageUrls[_currentImageIndex],
          fit: BoxFit.cover,
          width: MediaQuery.of(context).size.width * 0.8,
          errorBuilder: (_, __, ___) =>
          const Icon(Icons.broken_image, size: 50, color: Colors.grey),
        ),
      ),
    );
  }

  // MODIFIED: styled title & Merriweather treatment text
  Widget _buildTreatmentCard() {
    final theme = Theme.of(context);
    if (_treatmentOptions.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recommended Treatment',
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: const Color(0xFF2C3E50),
              ),
            ),
            const Divider(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: Text(
                _treatmentOptions[_currentTreatmentIndex],
                key: ValueKey<int>(_currentTreatmentIndex),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontFamily: 'Merriweather',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: const Color(0xFF003366),
                  height: 1.5,
                ),
              ),
            ),
            if (_treatmentOptions.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:
                  List.generate(_treatmentOptions.length, (index) {
                    return Container(
                      width: 8.0,
                      height: 8.0,
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentTreatmentIndex == index
                            ? theme.primaryColor
                            : Colors.grey.shade300,
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactList(
      String title, List<Map<String, dynamic>>? contacts, IconData icon) {
    final theme = Theme.of(context);
    if (contacts == null || contacts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: contacts.length,
          itemBuilder: (context, index) {
            final c = contacts[index];
            final name = c['name'] ??
                '${c['first_name'] ?? ''} ${c['last_name'] ?? ''}'.trim();
            final location = '${c['town']}, ${c['county']}';

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: CircleAvatar(child: Icon(icon)),
                title: Text(name),
                subtitle: Text(location),
                trailing: IconButton(
                  icon: Icon(Icons.phone, color: theme.primaryColor),
                  onPressed: () => _dial(c['contact'] as String?),
                ),
              ),
            );
          },
        ),
      ],
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
          _buildContactList(
              'Contact an Expert for Help', _extensionWorkers, Icons.support_agent),
        ],
      ),
    );
  }
}

