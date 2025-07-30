// lib/screens/login_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import 'diagnose_screen.dart';

const Color kLoginBackground = Color(0xFFF5F5F5);

/// ─────────────────────────────────────────────────────────────────────────────
/// 1) EMAIL LOGIN SCREEN
/// ─────────────────────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final resp = await http.post(
      Uri.parse('$backendBaseURL/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': _emailCtrl.text.trim(),
        'password': _passwordCtrl.text.trim(),
      }),
    );

    if (resp.statusCode == 200) {
      final jwt = jsonDecode(resp.body)['token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', jwt);

      // ◀ CHANGED: track a 7-day expiry so user stays logged in
      final expiry = DateTime.now().add(const Duration(days: 7));
      await prefs.setString('tokenExpiry', expiry.toIso8601String());

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DiagnoseScreen()),
        );
      }
    } else {
      final body = jsonDecode(resp.body);
      setState(() => _error = body['error'] ?? 'Login failed');
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;
    final fieldBg = Colors.white.withOpacity(0.1); // ◀ your translucent fill
    const errorColor = Color(0xFFD32F2F); // ◀ your error text

    return Scaffold(
      backgroundColor: kLoginBackground,
      // ◀ ensures scaffold itself is off-white
      appBar: AppBar(title: const Text('Email Login')),

      // ─── BODY: full-screen container to paint kLoginBackground everywhere ───
      body: Container(
        width: double.infinity, // ◀ NEW
        height: double.infinity, // ◀ NEW
        color: kLoginBackground, // ◀ NEW

        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 350, // ← PLAY WITH: 300, 350, 400
            ),
            child: Padding(
              padding: const EdgeInsets.all(16), // ← PLAY WITH: overall padding
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ─── Email Field ───────────────────────
                  TextField(
                    controller: _emailCtrl,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: fieldBg,
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14,
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  // ─── Password Field ────────────────────
                  TextField(
                    controller: _passwordCtrl,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: fieldBg,
                      labelText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14,
                      ),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),

                  // ─── Login Button ──────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600
                        ),
                        elevation: 4,
                      ),
                      child: _loading
                          ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2,
                        ),
                      )
                          : const Text('Login'),
                    ),
                  ),

                  // ─── Error Message ────────────────────
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!, style: const TextStyle(color: errorColor)),
                  ],

                  const SizedBox(height: 24),

                  // ─── “Don’t have an account?” ─────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? "),
                      TextButton(
                        onPressed: () =>
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RegisterScreen()),
                            ),
                        style: TextButton.styleFrom(
                          foregroundColor: secondaryColor,
                          textStyle: const TextStyle(fontWeight: FontWeight
                              .w600),
                        ),
                        child: const Text('Register'),
                      ),
                    ],
                  ),

                  // ─── “Forgot Password?” ───────────────
                  TextButton(
                    onPressed: () =>
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ForgotPasswordScreen()),
                        ),
                    style: TextButton.styleFrom(
                      foregroundColor: secondaryColor,
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Forgot Password?'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
/// ─────────────────────────────────────────────────────────────────────────────
/// 2) REGISTER SCREEN (in-file)
/// ─────────────────────────────────────────────────────────────────────────────
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLoginBackground,
      appBar: AppBar(title: const Text('Register')),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: kLoginBackground,
        child: const _RegisterForm(),
      ),
    );
  }
}

class _RegisterForm extends StatefulWidget {
  const _RegisterForm({Key? key}) : super(key: key);
  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _formKey        = GlobalKey<FormState>();
  final _firstNameCtrl  = TextEditingController();
  final _lastNameCtrl   = TextEditingController();
  final _emailCtrl      = TextEditingController();
  final _passwordCtrl   = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();          // ◀ CHANGED

  bool _loading = false;
  String? _error;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordCtrl.text.trim() != _confirmPwdCtrl.text.trim()) {
      setState(() => _error = 'Passwords do not match');    // ◀ CHANGED
      return;
    }

    setState(() {
      _loading = true;
      _error   = null;
    });

    final resp = await http.post(
      Uri.parse('$backendBaseURL/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'first_name': _firstNameCtrl.text.trim(),
        'last_name' : _lastNameCtrl.text.trim(),
        'email'     : _emailCtrl.text.trim(),
        'password'  : _passwordCtrl.text.trim(),
      }),
    );

    final theme          = Theme.of(context);
    final secondaryColor = theme.colorScheme.secondary;      // ◀ CHANGED

    if (resp.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Registered! Check your email.'),
          backgroundColor: secondaryColor,                   // ◀ CHANGED
        ),
      );
      Navigator.pop(context);
    } else {
      final body = jsonDecode(resp.body);
      setState(() => _error = body['error'] ?? 'Registration failed');
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme        = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final fieldBg      = Colors.white.withOpacity(0.1);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 350),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // — First Name —
                  TextFormField(
                    controller: _firstNameCtrl,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: fieldBg,
                      labelText: 'First Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12), // ← PLAY WITH

                  // — Last Name —
                  TextFormField(
                    controller: _lastNameCtrl,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: fieldBg,
                      labelText: 'Last Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  // — Email —
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: fieldBg,
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v != null && v.contains('@') ? null : 'Valid email',
                  ),
                  const SizedBox(height: 12),

                  // — Password —
                  TextFormField(
                    controller: _passwordCtrl,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: fieldBg,
                      labelText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    obscureText: true,
                    validator: (v) =>
                    v != null && v.length >= 8 ? null : 'Min 8 characters',
                  ),
                  const SizedBox(height: 12),

                  // — Confirm Password —                      // ◀ CHANGED
                  TextFormField(
                    controller: _confirmPwdCtrl,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: fieldBg,
                      labelText: 'Confirm Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    obscureText: true,
                    validator: (v) =>
                    v != _passwordCtrl.text ? 'Passwords do not match' : null,
                  ),
                  const SizedBox(height: 24),

                  // — Register Button —
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,    // ◀ CHANGED
                        foregroundColor: Colors.white,     // ◀ CHANGED
                        padding: const EdgeInsets.symmetric(
                          vertical: 14, // ← PLAY WITH
                        ),
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                          fontSize: 16,  // ← PLAY WITH
                          fontWeight: FontWeight.w600,
                        ),
                        elevation: 4,
                      ),
                      child: _loading
                          ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2,
                        ),
                      )
                          : const Text('Register'),
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!, style: TextStyle(color: Colors.red.shade700)), // ◀ CHANGED
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// 3) FORGOT PASSWORD SCREEN (in-file)
/// ─────────────────────────────────────────────────────────────────────────────
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLoginBackground,
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: kLoginBackground,
        child: const _ResetForm(),
      ),
    );
  }
}

class _ResetForm extends StatefulWidget {
  const _ResetForm({Key? key}) : super(key: key);
  @override
  State<_ResetForm> createState() => _ResetFormState();
}

class _ResetFormState extends State<_ResetForm> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _error, _message;

  Future<void> _requestReset() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email');
      return;
    }

    setState(() {
      _loading = true;
      _error   = null;
      _message = null;
    });

    try {
      final resp = await http.post(
        Uri.parse('$backendBaseURL/auth/request-reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      debugPrint('RESET ${resp.statusCode}: ${resp.body}');
      if (resp.statusCode == 200) {
        setState(() => _message = '✅ Reset link sent. Check your email.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Password reset email sent!'),
            backgroundColor: Theme.of(context).colorScheme.secondary, // ◀ CHANGED
          ),
        );
      } else {
        final body = jsonDecode(resp.body);
        final err  = body['error'] ?? 'Failed to send reset link';
        setState(() => _error = err);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err)), // ◀ CHANGED
        );
      }
    } catch (_) {
      setState(() => _error = 'Network error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme        = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final fieldBg      = Colors.white.withOpacity(0.1);
    const errorColor   = Color(0xFFD32F2F); // ◀ CHANGED

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 350),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // — Email Field —
              TextField(
                controller: _emailCtrl,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: fieldBg,
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),

              // — Send Reset Email Button —
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _requestReset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,    // ◀ CHANGED
                    foregroundColor: Colors.white,     // ◀ CHANGED
                    padding: const EdgeInsets.symmetric(
                      vertical: 14, // ← PLAY WITH
                    ),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontSize: 16, // ← PLAY WITH
                      fontWeight: FontWeight.w600,
                    ),
                    elevation: 4,
                  ),
                  child: _loading
                      ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2,
                    ),
                  )
                      : const Text('Send Reset Email'),
                ),
              ),

              if (_message != null) ...[
                const SizedBox(height: 16),
                Text(
                  _message!,
                  style: TextStyle(color: Theme.of(context).colorScheme.secondary), // ◀ CHANGED
                ),
              ],

              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: TextStyle(color: Colors.red.shade700)),          // ◀ CHANGED
              ],
            ],
          ),
        ),
      ),
    );
  }
}