// lib/screens/login_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import 'diagnose_screen.dart';

/// Email & Password Authentication:
///   • Register
///   • Login
///   • Request Password Reset
class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Register / Login / Forgot Password
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Email Authentication'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Register'),
              Tab(text: 'Login'),
              Tab(text: 'Forgot Password'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _RegisterTab(),
            _LoginTab(),
            _ResetTab(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1) REGISTER (EMAIL + PASSWORD) → POST /auth/register
// ─────────────────────────────────────────────────────────────────────────────
class _RegisterTab extends StatefulWidget {
  const _RegisterTab({Key? key}) : super(key: key);

  @override
  State<_RegisterTab> createState() => _RegisterTabState();
}

class _RegisterTabState extends State<_RegisterTab> {
  final _formKey        = GlobalKey<FormState>();
  final _firstNameCtrl  = TextEditingController();
  final _lastNameCtrl   = TextEditingController();
  final _emailCtrl      = TextEditingController();
  final _passwordCtrl   = TextEditingController();

  bool _loading = false;
  String? _error;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error   = null;
    });

    final response = await http.post(
      Uri.parse('$backendBaseURL/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'first_name': _firstNameCtrl.text.trim(),
        'last_name' : _lastNameCtrl.text.trim(),
        'email'     : _emailCtrl.text.trim(),
        'password'  : _passwordCtrl.text.trim(),
      }),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Registered! Check your email to verify.'),
        ),
      );
      // move to Login tab
      DefaultTabController.of(context)!.animateTo(1);
    } else {
      final body = jsonDecode(response.body);
      setState(() {
        _error = body['error'] ?? 'Registration failed';
      });
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // First Name
            TextFormField(
              controller: _firstNameCtrl,
              decoration: const InputDecoration(labelText: 'First Name'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),

            // Last Name
            TextFormField(
              controller: _lastNameCtrl,
              decoration: const InputDecoration(labelText: 'Last Name'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),

            // Email
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
              v != null && v.contains('@') ? null : 'Valid email required',
            ),
            const SizedBox(height: 12),

            // Password
            TextFormField(
              controller: _passwordCtrl,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: (v) =>
              v != null && v.length >= 8 ? null : 'Min 8 characters',
            ),
            const SizedBox(height: 24),

            // Register Button
            ElevatedButton(
              onPressed: _loading ? null : _register,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Register'),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2) LOGIN (EMAIL + PASSWORD) → POST /auth/login
// ─────────────────────────────────────────────────────────────────────────────
class _LoginTab extends StatefulWidget {
  const _LoginTab({Key? key}) : super(key: key);

  @override
  State<_LoginTab> createState() => _LoginTabState();
}

class _LoginTabState extends State<_LoginTab> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error   = null;
    });

    final response = await http.post(
      Uri.parse('$backendBaseURL/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email'   : _emailCtrl.text.trim(),
        'password': _passwordCtrl.text.trim(),
      }),
    );

    if (response.statusCode == 200) {
      final jwt   = jsonDecode(response.body)['token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', jwt);

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DiagnoseScreen()),
        );
      }
    } else {
      final body = jsonDecode(response.body);
      setState(() {
        _error = body['error'] ?? 'Login failed';
      });
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Email
          TextField(
            controller: _emailCtrl,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),

          // Password
          TextField(
            controller: _passwordCtrl,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
          const SizedBox(height: 24),

          // Login Button
          ElevatedButton(
            onPressed: _loading ? null : _login,
            child: _loading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Login'),
          ),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3) REQUEST PASSWORD RESET → POST /auth/request-reset
// ─────────────────────────────────────────────────────────────────────────────
class _ResetTab extends StatefulWidget {
  const _ResetTab({Key? key}) : super(key: key);

  @override
  State<_ResetTab> createState() => _ResetTabState();
}

class _ResetTabState extends State<_ResetTab> {
  final _emailCtrl = TextEditingController();

  bool _loading = false;
  String? _error;
  String? _message;

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

    final response = await http.post(
      Uri.parse('$backendBaseURL/auth/request-reset'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      setState(() => _message = '✅ Reset link sent. Check your email.');
    } else {
      final body = jsonDecode(response.body);
      setState(() {
        _error = body['error'] ?? 'Failed to send reset link';
      });
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Email
          TextField(
            controller: _emailCtrl,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 24),

          // Send Reset Email Button
          ElevatedButton(
            onPressed: _loading ? null : _requestReset,
            child: _loading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Send Reset Email'),
          ),

          if (_message != null) ...[
            const SizedBox(height: 16),
            Text(_message!, style: const TextStyle(color: Colors.green)),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
    );
  }
}