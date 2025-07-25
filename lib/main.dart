// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';             // ✅ Added for Firebase init

import 'config.dart';
import 'screens/landing_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/phone_registration_screen.dart';               // 📱 Your unified phone reg/login screen
import 'screens/otp_verification_screen.dart';
import 'screens/diagnose_screen.dart';
import 'screens/treatment_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();                              // 🔧 Initialize Firebase
  runApp(const CropHealthAIApp());
}

class CropHealthAIApp extends StatelessWidget {
  const CropHealthAIApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CropHealthAI',
      debugShowCheckedModeBanner: false,                        // ✂️ Removes the debug banner
      theme: ThemeData(
        useMaterial3: true,                                     // ✨ Opt into Material3
        colorSchemeSeed: Colors.green,                          // 🎨 Seeded color scheme
      ),
      initialRoute: '/',
      routes: {
        '/':        (ctx) => const LandingScreen(),             // 🏠 Landing / Welcome
        '/login':   (ctx) => const LoginScreen(),               // 📧 Email login & signup
        '/register':(ctx) => const RegisterScreen(),            // 📧 Email registration
        '/phone':   (ctx) => const PhoneRegistrationScreen(),   // 📱 Phone registration/login
        '/diagnose':(ctx) => const DiagnoseScreen(),            // 🌱 Diagnosis flow
      },
      // OTP screen is pushed directly from PhoneRegistrationScreen via MaterialPageRoute
    );
  }
}