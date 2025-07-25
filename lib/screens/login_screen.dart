// lib/screens/login_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

// Spacing constants
const double kDefaultPadding = 24.0;
const double kSmallSpacing   = 16.0;
const double kMediumSpacing  = 24.0;
const double kButtonHeight   = 50.0;

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController    = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    setState(() {
      _isLoading    = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('\$backendBaseURL/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email':    _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data  = jsonDecode(response.body);
        final token = data['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/diagnose');
        }
      } else {
        setState(() {
          _errorMessage = 'Login failed. Check your credentials.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: \$e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 🔄 Added: Forgot password dialog
  Future<void> _showForgotPasswordDialog() async {
    final TextEditingController emailController = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset Password'),
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Enter your email',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter your email.'))
                );
                return;
              }
              Navigator.pop(context);
              try {
                final resp = await http.post(
                  Uri.parse('\$backendBaseURL/auth/request-reset'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'email': email}),
                );
                if (resp.statusCode == 200) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password reset email sent.'))
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: \${resp.body}'))
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Network error: \$e'))
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme        = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onPrimary    = theme.colorScheme.onPrimary;

    return Scaffold(
      body: Stack(
        children: [
          // 1) Full-screen sunrise background
          Positioned.fill(
            child: Image.asset(
              'assets/bg_sunrise.png',
              fit: BoxFit.cover,
            ),
          ),
          // 2) Semi-transparent overlay
          Positioned.fill(
            child: Container(color: Colors.white.withOpacity(0.6)),
          ),
          // 3) Scrollable content
          SingleChildScrollView(
            padding: const EdgeInsets.all(kDefaultPadding),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: kMediumSpacing),
                  // Logo
                  Center(
                    child: Image.asset(
                      'assets/logo.jpeg',
                      height: 140,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: kMediumSpacing),

                  // Form Card
                  Card(
                    color: Colors.white.withOpacity(0.85),
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(kDefaultPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Welcome to CropHealthAI',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: kMediumSpacing),

                          // Email
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.email),
                              hintText: 'Email',
                            ),
                          ),
                          const SizedBox(height: kSmallSpacing),

                          // Password
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.lock),
                              hintText: 'Password',
                            ),
                          ),
                          const SizedBox(height: kSmallSpacing),

                          // Error message
                          if (_errorMessage != null) ...[
                            Text(
                              _errorMessage!,
                              style: TextStyle(color: theme.colorScheme.error),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: kSmallSpacing),
                          ],

                          // Login Button
                          ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: onPrimary,
                              minimumSize: const Size.fromHeight(kButtonHeight),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : const Text('Login', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: kSmallSpacing),

                          // 🔄 Forgot password link
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _showForgotPasswordDialog,
                              child: const Text('Forgot Password?'),
                            ),
                          ),

                          // Register link
                          TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(context, '/register'),
                            child: const Text(
                              "Don't have an account? Register",
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: kSmallSpacing),
                          const Divider(),
                          const SizedBox(height: kSmallSpacing),

                          // OR Separator
                          Center(
                            child: Text(
                              'OR',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: kSmallSpacing),

                          // Phone Login Button
                          OutlinedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/phone'),
                            icon: Icon(Icons.phone_android, color: primaryColor),
                            label: Text(
                              'Login with Phone',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: BorderSide(color: primaryColor, width: 2),
                              minimumSize: const Size.fromHeight(kButtonHeight),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: kMediumSpacing),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
