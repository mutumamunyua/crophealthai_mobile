// lib/screens/landing_screen.dart

import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'phone_registration_screen.dart';

// ─── CONSTANTS ───────────────────────────────────────────────────────────
const double kDefaultPadding    = 24.0;
const double kSmallSpacing      = 8.0;
const double kMediumSpacing     = 16.0;
const double kLogoSize          = 230.0;
const double kButtonHeight      = 50.0;
const double kStepContainerSize = 56.0;  // circle diameter
const double kStepIconSize      = 32.0;  // icon inside circle
const double kStepSpacing       = 10.0;  // gap between items

class LandingScreen extends StatelessWidget {
  const LandingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme        = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onPrimary    = theme.colorScheme.onPrimary;

    return Scaffold(
      body: Stack(
        children: [
          // ─── Full-screen sunrise background ─────────────────────────
          Positioned.fill(
            child: Image.asset(
              'assets/bg_sunrise.png',
              fit: BoxFit.cover,
            ),
          ),

          Column(
            children: [
              // ─── Top: logo, title, taglines, steps ───────────────────
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(kDefaultPadding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      SizedBox(
                        width: kLogoSize,
                        height: kLogoSize,
                        child: Image.asset('assets/logo.jpeg', fit: BoxFit.contain),
                      ),

                      const SizedBox(height: kMediumSpacing),

                      // English Title
                      Text(
                        'Welcome to CropHealthAI',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: kSmallSpacing),

                      // Taglines
                      Text(
                        'AI-powered crop diagnosis in your pocket',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: kSmallSpacing),
                      Text(
                        'Kilimo Bora kutumia technologia ya AI',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: kMediumSpacing * 1.5),

                      // Four-step sequence with arrows
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _StepItem(
                            icon: Icons.camera_alt,
                            label: 'Take\npicture',
                            color: primaryColor,
                          ),
                          const SizedBox(width: kStepSpacing),
                          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
                          const SizedBox(width: kStepSpacing),
                          _StepItem(
                            icon: Icons.analytics,
                            label: 'See\ndiag.',
                            color: primaryColor,
                          ),
                          const SizedBox(width: kStepSpacing),
                          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
                          const SizedBox(width: kStepSpacing),
                          _StepItem(
                            icon: Icons.science,
                            label: 'Get\ntreatment',
                            color: primaryColor,
                          ),
                          const SizedBox(width: kStepSpacing),
                          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
                          const SizedBox(width: kStepSpacing),
                          _StepItem(
                            icon: Icons.motorcycle,
                            label: 'Get\ndelivery',
                            color: primaryColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Bottom: login buttons ────────────────────────────────
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kDefaultPadding,
                    vertical: kMediumSpacing,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Email login/signup
                      SizedBox(
                        width: double.infinity,
                        height: kButtonHeight,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.email),
                          label: const Text('Login / Sign Up via Email'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => Navigator.pushNamed(context, '/login'),
                        ),
                      ),

                      const SizedBox(height: kMediumSpacing),

                      // Phone login/signup
                      SizedBox(
                        width: double.infinity,
                        height: kButtonHeight,
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.phone_android, color: primaryColor),
                          label: Text(
                            'Login / Sign Up via Phone',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: BorderSide(color: primaryColor, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => Navigator.pushNamed(context, '/phone'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A single step item: icon inside a circle + label below
class _StepItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StepItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: kStepContainerSize,
          height: kStepContainerSize,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(kStepContainerSize / 2),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Icon(icon, size: kStepIconSize, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
