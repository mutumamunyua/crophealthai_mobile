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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Ensures the Column doesn't take extra space
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium // Reduced from titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8.0),
        (contacts == null || contacts!.isEmpty)
            ? Container(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          alignment: Alignment.center,
          child: Text(
            'No professionals registered in this area yet.',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade600,
            ),
          ),
        )
        // 🔴 MODIFIED: Drastically reduced the height of the scroller
            : SizedBox(
          height: 95.0, // Reduced from 120.0
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
        '${contact['town'] ?? 'Unknown'}, ${contact['county'] ?? 'County'}';
    final phoneNumber = contact['contact'] as String?;

    // 🔴 MODIFIED: Made the card and all its contents much smaller
    return SizedBox(
      width: 140.0, // Reduced from 160.0
      child: Card(
        margin: const EdgeInsets.only(right: 10.0),
        elevation: 1.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top section with icon and name
              Row(
                children: [
                  CircleAvatar(
                    radius: 12, // Reduced
                    backgroundColor: theme.primaryColor.withOpacity(0.1),
                    child: Icon(icon, color: theme.primaryColor, size: 14), // Reduced
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12), // Reduced
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              // Location text
              Text(
                location,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 10), // Reduced
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              // Call button
              SizedBox(
                width: double.infinity,
                height: 24, // Reduced
                child: FilledButton.tonalIcon(
                  onPressed: () => _dial(phoneNumber),
                  icon: const Icon(Icons.phone, size: 12), // Reduced
                  label: const Text('Call'),
                  style: FilledButton.styleFrom(
                    textStyle: const TextStyle(
                      fontSize: 10, // Reduced
                      fontWeight: FontWeight.bold,
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