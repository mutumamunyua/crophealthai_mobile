// lib/screens/landing_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/weather_service.dart';
import 'login_screen.dart';
import 'phone_registration_screen.dart';
// 🔴 ADDED: Import for the professional registration screen
import 'professional_registration_screen.dart';

const double kDefaultPadding = 24.0;
const double kSmallSpacing = 8.0;
const double kMediumSpacing = 16.0;
const double kLogoSize = 230.0;
const double kButtonHeight = 50.0;
const double kStepContainerSize = 56.0;
const double kStepIconSize = 32.0;

class LandingScreen extends StatefulWidget {
  const LandingScreen({Key? key}) : super(key: key);

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final WeatherService _weatherService = WeatherService();

  double? temperature;
  double? windspeed;
  int? rain;
  int? humidity;
  List<String>? alerts;

  int _bannerIndex = 0;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _checkPermissionThenLoad();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkPermissionThenLoad() async {
    var status = await Geolocator.checkPermission();
    if (status == LocationPermission.denied) {
      status = await Geolocator.requestPermission();
    }
    if (status == LocationPermission.deniedForever) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Location Required'),
            content: const Text(
              'Enable location in settings to see weather and alerts.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Geolocator.openAppSettings();
                  Navigator.pop(context);
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
      return;
    }
    if (status == LocationPermission.always ||
        status == LocationPermission.whileInUse) {
      _initData();
    }
  }

  Future<Position?> _getCurrentLocation() async {
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _initData() async {
    final pos = await _getCurrentLocation();
    if (pos == null) return;

    final weatherFuture =
    _weatherService.fetchWeather(pos.latitude, pos.longitude);
    final alertsFuture =
    _weatherService.fetchAlerts(pos.latitude, pos.longitude);
    final results = await Future.wait([weatherFuture, alertsFuture]);

    final wd = results[0] as WeatherData?;
    final al = results[1] as List<String>?;

    if (!mounted) return;
    setState(() {
      temperature = wd?.temperature;
      windspeed = wd?.windspeed;
      rain = wd?.rain;
      humidity = wd?.humidity;
      alerts = al;
    });

    if (alerts == null || alerts!.isEmpty) {
      _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted) return;
        setState(() {
          _bannerIndex = (_bannerIndex + 1) % 4;
        });
      });
    }
  }

  Widget _buildBanner() {
    if (alerts != null && alerts!.isNotEmpty) {
      return Card(
        color: Colors.red[50],
        margin: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: alerts!
                .map((a) =>
                Text(a, style: const TextStyle(fontWeight: FontWeight.bold)))
                .toList(),
          ),
        ),
      );
    }

    final slides = [
      '☀️ Temp: ${temperature?.toStringAsFixed(1) ?? '--'}°C',
      '💨 Wind: ${windspeed?.toStringAsFixed(1) ?? '--'} km/h',
      '🌧 Rain: ${rain ?? 0} mm',
      '💧 Humidity: ${humidity ?? 0}%',
    ];
    const summary = '✅ Enjoy good growing conditions!';

    return Card(
      color: Colors.blue[50],
      margin: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              slides[_bannerIndex],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(summary, style: TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  // 🔴 ADDED: New method to build the footer actions

  Widget _buildFooterActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          kDefaultPadding, kMediumSpacing, kDefaultPadding, kDefaultPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 🔴 MODIFIED: Wrapped in Expanded to prevent overflow
          Expanded(
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProfessionalRegistrationScreen()),
                );
              },
              // Align text to the left within the button
              style: TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.zero,
              ),
              child: Text(
                "Register as a Professional",
                softWrap: true, // Allows text to wrap to a new line
                style: TextStyle(
                  fontSize: 13, // Made font smaller
                  color: Colors.white,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white,
                  decorationThickness: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16), // Ensures space between the two items

          // Your existing "Ask an Expert" button
          SizedBox(
            height: 40,
            child: FloatingActionButton.extended(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chat feature coming soon!')),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline, size: 20),
              label: const Text('Ask an Expert', style: TextStyle(fontSize: 12)),
              elevation: 6,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/bg_sunrise.jpeg', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
          SafeArea(
            child: Column(
              children: [
                if (temperature != null && windspeed != null)
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.6,
                      height: 30.0,
                      alignment: Alignment.center,
                      color: Colors.black54,
                      child: Text(
                        '${temperature!.toStringAsFixed(1)}°C · Wind: ${windspeed!.toStringAsFixed(1)} km/h',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
                      child: Column(
                        children: [
                          const SizedBox(height: kSmallSpacing),
                          SizedBox(
                            width: kLogoSize,
                            height: kLogoSize,
                            child: Image.asset('assets/logo.jpeg',
                                fit: BoxFit.contain),
                          ),
                          const SizedBox(height: kMediumSpacing),
                          Text(
                            'Welcome to CropHealthAI',
                            style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: kSmallSpacing),
                          Text(
                            'AI-powered crop diagnosis in your pocket',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: kSmallSpacing),
                          Text(
                            'Kilimo Bora kutumia technologia ya AI',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: kMediumSpacing * 1.5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _StepItem(
                                  icon: Icons.camera_alt,
                                  label: 'Take\npicture',
                                  color: primaryColor),
                              const Icon(Icons.arrow_forward_ios,
                                  size: 16, color: Colors.white70),
                              _StepItem(
                                  icon: Icons.analytics,
                                  label: 'See\ndiag.',
                                  color: primaryColor),
                              const Icon(Icons.arrow_forward_ios,
                                  size: 16, color: Colors.white70),
                              _StepItem(
                                  icon: Icons.science,
                                  label: 'Get\ntreatment',
                                  color: primaryColor),
                              const Icon(Icons.arrow_forward_ios,
                                  size: 16, color: Colors.white70),
                              _StepItem(
                                  icon: Icons.motorcycle,
                                  label: 'Get\ndelivery',
                                  color: primaryColor),
                            ],
                          ),
                          const SizedBox(height: kMediumSpacing),
                          _buildBanner(),
                          const SizedBox(height: kMediumSpacing),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.6,
                            height: kButtonHeight,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.email),
                              label: const Text('Login / Sign Up via Email'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: onPrimary,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LoginScreen()),
                              ),
                            ),
                          ),
                          const SizedBox(height: kMediumSpacing),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.6,
                            height: kButtonHeight,
                            child: OutlinedButton.icon(
                              icon: Icon(Icons.phone_android, color: primaryColor),
                              label: Text(
                                'Login / Sign Up via Phone',
                                style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold),
                              ),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: BorderSide(color: primaryColor, width: 2),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const PhoneRegistrationScreen()),
                              ),
                            ),
                          ),
                          // 🔴 MODIFIED: Replaced the old "Ask an Expert" button with the new footer actions row.
                          _buildFooterActions(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Icon(icon, size: kStepIconSize, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Colors.white),
        ),
      ],
    );
  }
}