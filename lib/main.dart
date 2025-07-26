// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'config.dart';
import 'screens/landing_screen.dart';
import 'screens/login_screen.dart';
import 'screens/phone_registration_screen.dart';
import 'screens/diagnose_screen.dart';
import 'screens/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const CropHealthAIApp());
}

class CropHealthAIApp extends StatelessWidget {
  const CropHealthAIApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CropHealthAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
      ),
      initialRoute: '/',
      routes: {
        // Landing & auth
        '/':        (_) => const LandingScreen(),
        '/login':   (_) => const LoginScreen(),
        '/register':(_) => const LoginScreen(),              // email signup on same screen
        '/phone':   (_) => const PhoneRegistrationScreen(),   // unified phone reg/login

        // Core flow
        '/diagnose':(_) => const DiagnoseScreen(),
        '/chat':    (_) => const ChatScreen(),
      },

      // Note: TreatmentScreen requires args, so we push it directly in DiagnoseScreen:
      // Navigator.push(context,
      //   MaterialPageRoute(builder: (_) => TreatmentScreen(...)));
      // No need to register a named '/treatment' route here.
    );
  }
}