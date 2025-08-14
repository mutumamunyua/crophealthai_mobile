// lib/widgets/contact_scroller.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactScroller extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>>? contacts;
  final IconData icon;

  const ContactScroller({
    super.key,
    required this.title,
    required this.contacts,
    required this.icon,
  });

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
    if (contacts == null || contacts!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold, fontSize: 18), // Reduced font size
        ),
        const SizedBox(height: 8.0), // Reduced spacing
        // 🔴 MODIFIED: Reduced height for a more compact scroller
        SizedBox(
          height: 140.0, // Reduced from 150.0
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: contacts!.length,
            itemBuilder: (context, index) {
              final contact = contacts![index];
              return _buildContactCard(context, contact);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard(
      BuildContext context, Map<String, dynamic> contact) {
    final theme = Theme.of(context);
    final name = contact['name'] ??
        '${contact['first_name'] ?? ''} ${contact['last_name'] ?? ''}'.trim();
    final location =
        '${contact['town'] ?? 'Unknown Town'}, ${contact['county'] ?? 'Unknown County'}';
    final phoneNumber = contact['contact'] as String?;

    // 🔴 MODIFIED: Reduced width for a more compact card
    return SizedBox(
      width: 165.0, // Reduced from 180.0
      child: Card(
        margin: const EdgeInsets.only(right: 12.0),
        elevation: 2.0, // Reduced elevation
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0), // Reduced padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceAround, // Adjusted spacing
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16, // Reduced radius
                    backgroundColor: theme.primaryColor.withOpacity(0.1),
                    child: Icon(icon, color: theme.primaryColor, size: 18), // Reduced size
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold, fontSize: 14), // Reduced size
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Text(
                location,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: Colors.grey.shade700, fontSize: 12), // Reduced size
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(
                width: double.infinity,
                height: 30, // Added fixed height
                child: FilledButton.tonalIcon(
                  onPressed: () => _dial(phoneNumber),
                  icon: const Icon(Icons.phone, size: 14), // Reduced size
                  label: const Text('Call'),
                  style: FilledButton.styleFrom(
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12, // Reduced size
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}