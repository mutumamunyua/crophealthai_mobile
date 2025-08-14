// FILE: lib/main.dart
// FIX: This file is now corrected to ALWAYS start the app on your LandingScreen, as you originally designed.

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/landing_screen.dart'; // <-- IMPORT YOUR LANDING SCREEN
import 'screens/phone_registration_screen.dart';
import 'screens/diagnose_screen.dart';

Future<void> main() async {
  // These two lines are still necessary for Firebase to work correctly.
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
      // ✅ FIX: The app will ALWAYS start on your LandingScreen now.
      initialRoute: '/landing',
      routes: {
        // Define all the possible routes for your app
        '/landing': (_) => const LandingScreen(),
        '/login_phone': (_) => const PhoneRegistrationScreen(),
        '/diagnose': (_) => const DiagnoseScreen(),
        // You can add your email login route here later
      },
    );
  }
}
