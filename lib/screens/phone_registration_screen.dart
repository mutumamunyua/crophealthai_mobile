// lib/screens/phone_registration_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../config.dart';             // for backendBaseURL
import 'diagnose_screen.dart';       // navigate on success

class PhoneRegistrationScreen extends StatelessWidget {
  const PhoneRegistrationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,  // Register, Login, Forgot PIN
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Phone Authentication'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Register'),
              Tab(text: 'Login'),
              Tab(text: 'Forgot PIN'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _RegisterTab(),
            _LoginTab(),
            _ResetPinTab(),
          ],
        ),
      ),
    );
  }
}

// ─── 1) REGISTER ────────────────────────────────────────────────────────────
// Phone → PIN + confirm → Send OTP → Enter OTP → POST /auth/phone/register
class _RegisterTab extends StatefulWidget {
  const _RegisterTab({Key? key}) : super(key: key);
  @override
  State<_RegisterTab> createState() => _RegisterTabState();
}

class _RegisterTabState extends State<_RegisterTab> {
  String? _rawPhone;
  String? _verificationId;
  final _pinCtrl        = TextEditingController();
  final _confirmPinCtrl = TextEditingController();
  final _otpCtrl        = TextEditingController();
  bool   _otpSent  = false, _loading = false;
  String? _error;

  Future<void> _sendOtp() async {
    final pin  = _pinCtrl.text.trim();
    final conf = _confirmPinCtrl.text.trim();
    if (_rawPhone == null || pin.length != 4 || pin != conf) {
      setState(() => _error = 'Phone & matching 4-digit PINs required');
      return;
    }
    setState(() { _loading = true; _error = null; });
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: _rawPhone!,
      timeout: const Duration(seconds: 60),
      codeSent: (verifId, _) {
        setState(() {
          _verificationId = verifId;
          _otpSent = true;
        });
      },
      verificationCompleted: (_) {},
      verificationFailed: (e) => setState(() => _error = e.message),
      codeAutoRetrievalTimeout: (_) {},
    );
    setState(() { _loading = false; });
  }

  Future<void> _verifyAndRegister() async {
    final otp = _otpCtrl.text.trim();
    final pin = _pinCtrl.text.trim();
    if (otp.length != 6) {
      setState(() => _error = 'Enter a 6-digit OTP');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      final uc = await FirebaseAuth.instance.signInWithCredential(cred);
      final idToken = await uc.user?.getIdToken() ?? (throw 'No token');

      final resp = await http.post(
        Uri.parse('$backendBaseURL/auth/phone/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_token': idToken, 'pin': pin}),
      );

      if (resp.statusCode == 200) {
        final jwt = jsonDecode(resp.body)['token'] as String;
        await SharedPreferences.getInstance().then((p) => p.setString('token', jwt));
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DiagnoseScreen()),
        );
      } else {
        final body = jsonDecode(resp.body);
        setState(() => _error = body['error'] ?? 'Registration failed');
      }
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (!_otpSent) ...[
            IntlPhoneField(
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: UnderlineInputBorder(),
              ),
              initialCountryCode: 'KE',
              onChanged: (p) => _rawPhone = p.completeNumber,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pinCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'Set PIN (4 digits)',
                border: UnderlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPinCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'Confirm PIN',
                border: UnderlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _sendOtp,
              child: _loading
                  ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Send OTP'),
            ),
          ] else ...[
            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Enter OTP',
                border: UnderlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _verifyAndRegister,
              child: _loading
                  ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Verify & Register'),
            ),
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

// ─── 2) LOGIN ────────────────────────────────────────────────────────────────
// Phone → PIN only → POST /auth/phone/login-pin
class _LoginTab extends StatefulWidget {
  const _LoginTab({Key? key}) : super(key: key);
  @override
  State<_LoginTab> createState() => _LoginTabState();
}

class _LoginTabState extends State<_LoginTab> {
  String? _rawPhone;
  final _pinCtrl = TextEditingController();
  bool   _loading = false;
  String? _error;

  Future<void> _loginWithPin() async {
    final pin = _pinCtrl.text.trim();
    if (_rawPhone == null || pin.length != 4) {
      setState(() => _error = 'Phone & 4-digit PIN required');
      return;
    }
    setState(() { _loading = true; _error = null; });

    try {
      final resp = await http.post(
        Uri.parse('$backendBaseURL/auth/phone/login-pin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': _rawPhone, 'pin': pin}),
      );

      if (resp.statusCode == 200) {
        final jwt = jsonDecode(resp.body)['token'] as String;
        await SharedPreferences.getInstance().then((p) => p.setString('token', jwt));
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DiagnoseScreen()),
        );
      } else {
        final body = jsonDecode(resp.body);
        setState(() => _error = body['error'] ?? 'Login failed');
      }
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          IntlPhoneField(
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              border: UnderlineInputBorder(),
            ),
            initialCountryCode: 'KE',
            keyboardType: TextInputType.phone,
            onChanged: (p) {
              // strip any leading zero from the local number, then re-prefix:
              var local = p.number;
              if (local.startsWith('0')) local = local.substring(1);
              _rawPhone = '${p.countryCode}$local';
            },
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _pinCtrl,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: const InputDecoration(
              labelText: 'Enter PIN',
              border: UnderlineInputBorder(),
              counterText: '',
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _loginWithPin,
            child: _loading
                ? const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Login with PIN'),
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

// ─── 3) FORGOT PIN ───────────────────────────────────────────────────────────
// Phone → Send OTP → OTP + new PIN + confirm → POST /auth/phone/reset-pin
class _ResetPinTab extends StatefulWidget {
  const _ResetPinTab({Key? key}) : super(key: key);
  @override
  State<_ResetPinTab> createState() => _ResetPinTabState();
}

class _ResetPinTabState extends State<_ResetPinTab> {
  String? _rawPhone;
  String? _verificationId;
  final _otpCtrl        = TextEditingController();
  final _newPinCtrl     = TextEditingController();
  final _confirmPinCtrl = TextEditingController();
  bool   _otpSent  = false, _loading = false;
  String? _error;

  Future<void> _sendOtp() async {
    if (_rawPhone == null) {
      setState(() => _error = 'Enter phone first');
      return;
    }
    setState(() { _loading = true; _error = null; });

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: _rawPhone!,
      timeout: const Duration(seconds: 60),
      codeSent: (verifId, _) {
        setState(() {
          _verificationId = verifId;
          _otpSent = true;
        });
      },
      verificationCompleted: (_) {},
      verificationFailed: (e) => setState(() => _error = e.message),
      codeAutoRetrievalTimeout: (_) {},
    );

    setState(() { _loading = false; });
  }

  Future<void> _verifyAndReset() async {
    final otp    = _otpCtrl.text.trim();
    final newPin = _newPinCtrl.text.trim();
    final conf   = _confirmPinCtrl.text.trim();

    if (otp.length != 6 || newPin.length != 4 || newPin != conf) {
      setState(() => _error = 'OTP + matching 4-digit PINs required');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      final uc = await FirebaseAuth.instance.signInWithCredential(cred);
      final idToken = await uc.user?.getIdToken() ?? '';

      final resp = await http.post(
        Uri.parse('$backendBaseURL/auth/phone/reset-pin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_token': idToken, 'new_pin': newPin}),
      );

      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ PIN updated! Please login with new PIN'),
          ),
        );
        // switch back to Login tab
        DefaultTabController.of(context)?.animateTo(1);
        setState(() {
          _otpSent = false;
          _otpCtrl.clear();
          _newPinCtrl.clear();
          _confirmPinCtrl.clear();
        });
      } else {
        final body = jsonDecode(resp.body);
        setState(() => _error = body['error'] ?? 'Reset failed');
      }
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext c) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (!_otpSent) ...[
            IntlPhoneField(
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: UnderlineInputBorder(),
              ),
              initialCountryCode: 'KE',
              keyboardType: TextInputType.phone,
              onChanged: (p) {
                // strip any leading zero from the local number, then re-prefix:
                var local = p.number;
                if (local.startsWith('0')) local = local.substring(1);
                _rawPhone = '${p.countryCode}$local';
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _sendOtp,
              child: _loading
                  ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Send OTP'),
            ),
          ] else ...[
            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Enter OTP',
                border: UnderlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPinCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'New PIN',
                border: UnderlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPinCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'Confirm PIN',
                border: UnderlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _verifyAndReset,
              child: _loading
                  ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Reset PIN'),
            ),
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