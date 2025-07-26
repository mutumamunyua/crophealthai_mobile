// lib/screens/treatment_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // for dialing phone numbers

/// A screen that shows the disease name, treatment steps (with images),
/// and nearby agrovets & extension workers.
class TreatmentScreen extends StatelessWidget {
  final String disease;
  final String treatmentText;
  final List<String>? imageUrls;
  final List<Map<String, dynamic>>? agrovets;
  final List<Map<String, dynamic>>? extensionWorkers;

  const TreatmentScreen({
    Key? key,
    required this.disease,
    required this.treatmentText,
    this.imageUrls,
    this.agrovets,
    this.extensionWorkers,
  }) : super(key: key);

  void _launchPhone(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildImageCarousel() {
    if (imageUrls == null || imageUrls!.isEmpty) {
      return const Text('No treatment images available.');
    }
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls!.length,
        itemBuilder: (ctx, i) => Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrls![i],
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[200],
                width: 200,
                height: 200,
                child: const Icon(Icons.broken_image, size: 48),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(Map<String, dynamic> item, {bool isAgrovet = true}) {
    final name = isAgrovet
        ? item['name'] ?? 'Unknown Agrovet'
        : '${item['first_name'] ?? ''} ${item['last_name'] ?? ''}'.trim();
    final location = '${item['town'] ?? 'N/A'}, ${item['county'] ?? 'N/A'}';
    final contact = item['contact'] ?? 'N/A';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(name),
        subtitle: Text(location),
        trailing: IconButton(
          icon: const Icon(Icons.phone),
          onPressed: () {
            if (contact != 'N/A') _launchPhone(contact);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Treatment for $disease'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Treatment text
            _buildSectionTitle(context, 'Recommended Treatment'),
            Text(
              treatmentText,
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            // Images
            const SizedBox(height: 16),
            _buildSectionTitle(context, 'Treatment Images'),
            _buildImageCarousel(),

            // Nearby Agrovet stores
            const SizedBox(height: 16),
            if (agrovets != null && agrovets!.isNotEmpty) ...[
              _buildSectionTitle(context, 'Nearby Agrovet Stores'),
              ...agrovets!
                  .map((a) => _buildContactCard(a, isAgrovet: true))
                  .toList(),
            ],

            // Extension workers
            const SizedBox(height: 16),
            if (extensionWorkers != null && extensionWorkers!.isNotEmpty) ...[
              _buildSectionTitle(context, 'Nearby Extension Workers'),
              ...extensionWorkers!
                  .map((w) => _buildContactCard(w, isAgrovet: false))
                  .toList(),
            ],

            // Fallback if neither list has items
            if ((agrovets == null || agrovets!.isEmpty) &&
                (extensionWorkers == null || extensionWorkers!.isEmpty))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No nearby services found.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}