// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// 🔴 ADDED: Import for persistent storage
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'screens/landing_screen.dart';
import 'screens/diagnose_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KILIMO AFYA',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // 🔴 MODIFIED: The app now starts with our new AuthCheckScreen
      home: const AuthCheckScreen(),
    );
  }
}

// 🔴 ADDED: A new screen to check the user's login status on startup
class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final expiryString = prefs.getString('tokenExpiry');

    // If there is no token or no expiry date, go to the landing screen
    if (token == null || expiryString == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LandingScreen()),
      );
      return;
    }

    final expiryDate = DateTime.parse(expiryString);

    // If the token is expired, go to the landing screen
    if (DateTime.now().isAfter(expiryDate)) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LandingScreen()),
      );
    } else {
      // If the token is valid and not expired, go directly to the diagnose screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DiagnoseScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading spinner while we check the login status
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
