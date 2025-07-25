// lib/screens/treatment_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../config.dart';

// ─── SPACING CONSTANTS ─────────────────────────────────────────────────
const double kDefaultPadding = 24.0;
const double kSmallSpacing   = 12.0;
const double kMediumSpacing  = 24.0;
const double kButtonHeight   = 50.0;

class TreatmentScreen extends StatefulWidget {
  final String disease;

  const TreatmentScreen({
    Key? key,
    required this.disease,
  }) : super(key: key);

  @override
  State<TreatmentScreen> createState() => _TreatmentScreenState();
}

class _TreatmentScreenState extends State<TreatmentScreen> {
  bool _isLoading = true;
  String? _error;

  // ✅ NEW: Data coming from the Flask `/utils/treatments/...` response
  String? _treatmentText;
  List<String>? _treatmentImages;
  List<dynamic>? _agrovets;
  List<dynamic>? _extensionWorkers;

  @override
  void initState() {
    super.initState();
    _fetchTreatment();
  }

  Future<void> _fetchTreatment() async {
    setState(() {
      _isLoading = true;
      _error     = null;
    });

    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      pos = null; // no location
    }

    final query = <String, String>{};
    if (pos != null) {
      query['latitude']  = pos.latitude.toString();
      query['longitude'] = pos.longitude.toString();
    }

    final uri = Uri.parse(
      '$backendBaseURL/utils/treatments/${Uri.encodeComponent(widget.disease)}',
    ).replace(queryParameters: query);

    try {
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        setState(() {
          _treatmentText     = data['treatment'] as String;
          _treatmentImages   = List<String>.from(data['treatment_images'] ?? []);
          _agrovets          = List<dynamic>.from(data['agrovets'] ?? []);
          _extensionWorkers  = List<dynamic>.from(data['extension_workers'] ?? []);
          _isLoading         = false;
        });
      } else {
        setState(() {
          _error     = 'Error ${res.statusCode}: ${res.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error     = 'Failed to load treatment: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildListSection<T>(
      String title,
      List<T>? items,
      Widget Function(T) itemBuilder,
      ) {
    if (items == null || items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: kSmallSpacing),
        ...items.map(itemBuilder).toList(),
        const SizedBox(height: kMediumSpacing),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Treatment for ${widget.disease}'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text(_error!, style: theme.textTheme.bodyLarge?.copyWith(color: Colors.red)))
              : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Treatment Text ──────────────────────
                Text(
                  'Recommendation',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: kSmallSpacing),
                Text(
                  _treatmentText ?? 'No treatment info available.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: kMediumSpacing),

                // ─── Treatment Images ────────────────────
                if (_treatmentImages != null && _treatmentImages!.isNotEmpty) ...[
                  Text('Images', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: kSmallSpacing),
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _treatmentImages!.length,
                      separatorBuilder: (_, __) => const SizedBox(width: kSmallSpacing),
                      itemBuilder: (context, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _treatmentImages![i],
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: kMediumSpacing),
                ],

                // ─── Nearby Agrovets ────────────────────
                _buildListSection<Map<String, dynamic>>(
                  'Nearby Agrovets',
                  _agrovets,
                      (agro) => Card(
                    child: ListTile(
                      title: Text(agro['name'] ?? 'Unknown'),
                      subtitle: Text('${agro['town']}, ${agro['county']}'),
                      trailing: Icon(Icons.store_mall_directory),
                    ),
                  ),
                ),

                // ─── Nearby Extension Workers ───────────
                _buildListSection<Map<String, dynamic>>(
                  'Nearby Extension Workers',
                  _extensionWorkers,
                      (w) => Card(
                    child: ListTile(
                      title: Text('${w['first_name']} ${w['last_name']}'),
                      subtitle: Text('${w['town']}, ${w['county']}'),
                      trailing: Icon(Icons.engineering),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}