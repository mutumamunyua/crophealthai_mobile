// lib/screens/landing_screen.dart

import 'dart:async';                                    // for Timer
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';            // ✅ ADDED: geolocator for location
import '../services/weather_service.dart';              // ✅ ADDED: our weather/alerts service
import 'login_screen.dart';
import 'phone_registration_screen.dart';

// ─── SPACING & SIZE CONSTANTS ───────────────────────────────────────────
const double kDefaultPadding     = 24.0;
const double kSmallSpacing       = 8.0;
const double kMediumSpacing      = 16.0;
const double kLogoSize           = 230.0;
const double kButtonHeight       = 50.0;
const double kStepContainerSize  = 56.0;
const double kStepIconSize       = 32.0;

class LandingScreen extends StatefulWidget {
  const LandingScreen({Key? key}) : super(key: key);

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final WeatherService _weatherService = WeatherService(); // ✅ ADDED

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
    _checkPermissionThenLoad(); // 🔄 UPDATED: request permission before loading
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  // ✅ NEW: check/request location permission, then call _initData()
  Future<void> _checkPermissionThenLoad() async {
    var status = await Geolocator.checkPermission();
    if (status == LocationPermission.denied) {
      status = await Geolocator.requestPermission();
    }
    if (status == LocationPermission.deniedForever) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) =>
              AlertDialog(
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
      _initData(); // 🔄 UPDATED: only call _initData after permission
    }
  }

  // 🔄 UPDATED: simply return position (permission already handled)
  Future<Position?> _getCurrentLocation() async {
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // existing: fetch weather & alerts
  Future<void> _initData() async {
    final pos = await _getCurrentLocation();
    if (pos == null) return;

    final weatherFuture = _weatherService.fetchWeather(
        pos.latitude, pos.longitude);
    final alertsFuture = _weatherService.fetchAlerts(
        pos.latitude, pos.longitude);
    final results = await Future.wait([weatherFuture, alertsFuture]);

    final wd = results[0] as WeatherData?;
    final al = results[1] as List<String>?;

    setState(() {
      temperature = wd?.temperature;
      windspeed = wd?.windspeed;
      rain = wd?.rain;
      humidity = wd?.humidity;
      alerts = al;
    });

    if (alerts == null || alerts!.isEmpty) {
      _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        setState(() {
          _bannerIndex = (_bannerIndex + 1) % 4;
        });
      });
    }
  }

  // existing: build rotating or alert banner
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;

    return Scaffold(
      body: Stack(
        children: [
          // ─── background layers ───────────────────────────────
          Positioned.fill(
            child: Image.asset('assets/bg_sunrise.jpeg', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),

          // ─── foreground content ───────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // 🔄 weather strip
                /*if (temperature != null && windspeed != null)
                  Container(
                    width: double.infinity,
                    color: Colors.black54,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '${temperature!.toStringAsFixed(1)}°C · Wind: ${windspeed!.toStringAsFixed(1)} km/h',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  */
                // ─── 1) WEATHER STRIP ─────────────────────────────────────
                if (temperature != null && windspeed != null)
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: MediaQuery
                          .of(context)
                          .size
                          .width * 0.6,
                      // ← PLAY WITH: 0.5, 0.6, 0.7…
                      height: 30.0,
                      // ← PLAY WITH: try 30, 35, 40…
                      alignment: Alignment.center,
                      color: Colors.black54,
                      child: Text(
                        '${temperature!.toStringAsFixed(
                            1)}°C · Wind: ${windspeed!.toStringAsFixed(
                            1)} km/h',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14, // ← PLAY WITH: 12, 14, 16…
                        ),
                      ),
                    ),
                  ),

                // make everything else scrollable
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      kDefaultPadding, // left
                      8.0, // top    ← PLAY WITH: try 4, 8, 12…
                      kDefaultPadding, // right
                      8.0, // bottom ← PLAY WITH: try 8, 16, 24…
                    ),
                    child: Column(
                      children: [
                        // ─── logo & taglines ───────────────────────
                        SizedBox(
                          width: kLogoSize,
                          height: kLogoSize,
                          child: Image.asset('assets/logo.jpeg', fit: BoxFit
                              .contain),
                        ),
                        const SizedBox(height: kMediumSpacing),
                        Text(
                          'Welcome to CropHealthAI',
                          style: theme.textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold,
                              color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: kSmallSpacing),
                        Text(
                          'AI-powered crop diagnosis in your pocket',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: kSmallSpacing),
                        Text(
                          'Kilimo Bora kutumia technologia ya AI',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontStyle: FontStyle.italic,
                              color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: kMediumSpacing * 1.5),

                        // ─── step icons ────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _StepItem(
                              icon: Icons.camera_alt,
                              label: 'Take\npicture',
                              color: primaryColor,
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16,
                                color: Colors.white70),
                            _StepItem(
                              icon: Icons.analytics,
                              label: 'See\ndiag.',
                              color: primaryColor,
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16,
                                color: Colors.white70),
                            _StepItem(
                              icon: Icons.science,
                              label: 'Get\ntreatment',
                              color: primaryColor,
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16,
                                color: Colors.white70),
                            _StepItem(
                              icon: Icons.motorcycle,
                              label: 'Get\ndelivery',
                              color: primaryColor,
                            ),
                          ],
                        ),

                        const SizedBox(height: kMediumSpacing),

                        // ─── rotating/flashing banner ──────────────
                        _buildBanner(),

                        const SizedBox(height: kMediumSpacing),

                        // ─── login buttons ─────────────────────────
                        SizedBox(
                          //width: double.infinity,
                          width: MediaQuery
                              .of(context)
                              .size
                              .width * 0.6,
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
                            onPressed: () =>
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const LoginScreen()),
                                ),
                          ),
                        ),
                        const SizedBox(height: kMediumSpacing),
                        SizedBox(
                          //width: double.infinity,
                          width: MediaQuery
                              .of(context)
                              .size
                              .width * 0.6,
                          height: kButtonHeight,
                          child: OutlinedButton.icon(
                            icon: Icon(
                                Icons.phone_android, color: primaryColor),
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
                            onPressed: () =>
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (
                                      _) => const PhoneRegistrationScreen()),
                                ),
                          ),
                        ),
                        // ─── chat button ───────────────────────────
                        const SizedBox(height: kMediumSpacing),
                        Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            height: 40, // ← PLAY WITH: try 30, 35, 40, etc.
                            child: FloatingActionButton.extended(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text(
                                      'Chat feature coming soon!')),
                                );
                              },
                              icon: const Icon(
                                  Icons.chat_bubble_outline, size: 20),
                              label: const Text(
                                'Ask an Expert',
                                style: TextStyle(
                                    fontSize: 12), // ← PLAY WITH: 10, 12, 14…
                              ),
                              elevation: 6,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
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
    Key? key,
  }) : super(key: key);

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
              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
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
