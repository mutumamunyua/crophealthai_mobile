// lib/screens/phone_auth_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl_phone_field/intl_phone_field.dart';          // 🚀 Country code & flag support
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'diagnose_screen.dart';                                    // 🏠 Navigate on success

class PhoneAuthScreen extends StatelessWidget {
  const PhoneAuthScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, // Register, OTP Login, PIN Login, Reset PIN
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Phone Authentication'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Register'),
              Tab(text: 'Login (OTP)'),
              Tab(text: 'Login (PIN)'),
              Tab(text: 'Reset PIN'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _RegisterTab(),
            _OtpLoginTab(),
            _PinLoginTab(),
            _ResetPinTab(),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────────
// 1) REGISTER VIA PHONE → OTP → Set PIN + Names → /auth/phone/register
// ───────────────────────────────────────────────────────────────────────────────
class _RegisterTab extends StatefulWidget {
  const _RegisterTab({Key? key}) : super(key: key);
  @override
  State<_RegisterTab> createState() => _RegisterTabState();
}

class _RegisterTabState extends State<_RegisterTab> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl  = TextEditingController();
  final _otpCtrl       = TextEditingController();
  final _pinCtrl       = TextEditingController();
  String? _rawPhone;
  String? _verificationId;
  int?    _resendToken;
  bool   _otpSent     = false;
  bool   _loading     = false;
  String? _error;

  Future<void> _sendOtp() async {
    if (_firstNameCtrl.text.trim().isEmpty || _lastNameCtrl.text.trim().isEmpty || _rawPhone == null) {
      setState(() => _error = 'Phone, first & last names are required');
      return;
    }
    setState(() {
      _loading = true;
      _error   = null;
    });
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: _rawPhone!,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (cred) async {
        // auto-retrieval
      },
      verificationFailed: (e) {
        setState(() => _error = e.message);
      },
      codeSent: (verifId, token) {
        setState(() {
          _verificationId = verifId;
          _resendToken   = token;
          _otpSent       = true;
        });
      },
      codeAutoRetrievalTimeout: (_) {},
    );
    setState(() => _loading = false);
  }

  Future<void> _verifyAndRegister() async {
    final otp = _otpCtrl.text.trim();
    final pin = _pinCtrl.text.trim();
    if (otp.length != 6 || pin.length != 4) {
      setState(() => _error = 'Enter 6-digit OTP and 4-digit PIN');
      return;
    }
    setState(() {
      _loading = true;
      _error   = null;
    });

    try {
      // 1) Verify OTP
      final cred = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      final uc = await FirebaseAuth.instance.signInWithCredential(cred);
      final idToken = await uc.user?.getIdToken();
      if (idToken == null) throw 'No Firebase token';

      // 2) Call backend
      final resp = await http.post(
        Uri.parse('$backendBaseURL/auth/phone/register'),     // 📍 phone/register
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_token': idToken,
          'pin'      : pin,
          'first_name': _firstNameCtrl.text.trim(),
          'last_name' : _lastNameCtrl.text.trim(),
        }),
      );

      if (resp.statusCode == 200) {
        final jwt = jsonDecode(resp.body)['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', jwt);
        if (context.mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DiagnoseScreen()));
        }
      } else {
        setState(() => _error = jsonDecode(resp.body)['error'] ?? 'Register failed');
      }
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      setState(() => _loading = false);
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
              decoration: const InputDecoration(labelText: 'Phone Number'),
              initialCountryCode: 'KE',
              onChanged: (phone) => _rawPhone = phone.completeNumber,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _firstNameCtrl,
              decoration: const InputDecoration(labelText: 'First Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lastNameCtrl,
              decoration: const InputDecoration(labelText: 'Last Name'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _sendOtp,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Send OTP'),
            ),
          ] else ...[
            TextField(
              controller: _otpCtrl,
              decoration: const InputDecoration(labelText: '6-digit OTP'),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pinCtrl,
              decoration: const InputDecoration(labelText: 'Set 4-digit PIN'),
              keyboardType: TextInputType.number,
              maxLength: 4,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _verifyAndRegister,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Verify & Register'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loading ? null : _sendOtp,
              child: const Text('Resend OTP'),
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

// ───────────────────────────────────────────────────────────────────────────────
// 2) LOGIN VIA OTP → Enter PIN → /auth/phone/login
// ───────────────────────────────────────────────────────────────────────────────
class _OtpLoginTab extends StatefulWidget {
  const _OtpLoginTab({Key? key}) : super(key: key);
  @override
  State<_OtpLoginTab> createState() => _OtpLoginTabState();
}

class _OtpLoginTabState extends State<_OtpLoginTab> {
  final _otpCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  String? _rawPhone;
  String? _verificationId;
  int?    _resendToken;
  bool   _otpSent = false;
  bool   _loading = false;
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
      verificationCompleted: (cred) async {},
      verificationFailed: (e) => setState(() => _error = e.message),
      codeSent: (vid, tok) => setState(() {
        _verificationId = vid;
        _resendToken   = tok;
        _otpSent       = true;
      }),
      codeAutoRetrievalTimeout: (_) {},
    );
    setState(() { _loading = false; });
  }

  Future<void> _verifyAndLogin() async {
    final otp = _otpCtrl.text.trim();
    final pin = _pinCtrl.text.trim();
    if (otp.length != 6 || pin.length != 4) {
      setState(() => _error = 'Provide OTP + PIN');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final cred = PhoneAuthProvider.credential(
          verificationId: _verificationId!, smsCode: otp);
      final uc = await FirebaseAuth.instance.signInWithCredential(cred);
      final idToken = await uc.user?.getIdToken();

      final resp = await http.post(
        Uri.parse('$backendBaseURL/auth/phone/login'),     // 📍 phone/login
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_token': idToken, 'pin': pin}),
      );

      if (resp.statusCode == 200) {
        final jwt = jsonDecode(resp.body)['token'];
        await SharedPreferences.getInstance().then((p) => p.setString('token', jwt));
        if (context.mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DiagnoseScreen()));
        }
      } else {
        setState(() => _error = jsonDecode(resp.body)['error'] ?? 'Login failed');
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
              decoration: const InputDecoration(labelText: 'Phone Number'),
              initialCountryCode: 'KE',
              onChanged: (p) => _rawPhone = p.completeNumber,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _sendOtp,
              child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Send OTP'),
            ),
          ] else ...[
            TextField(
              controller: _otpCtrl,
              decoration: const InputDecoration(labelText: '6-digit OTP'),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pinCtrl,
              decoration: const InputDecoration(labelText: 'Enter PIN'),
              keyboardType: TextInputType.number,
              maxLength: 4,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _verifyAndLogin,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Login'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loading ? null : _sendOtp,
              child: const Text('Resend OTP'),
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

// ───────────────────────────────────────────────────────────────────────────────
// 3) PIN-ONLY LOGIN → /auth/phone/login-pin
// ───────────────────────────────────────────────────────────────────────────────
class _PinLoginTab extends StatefulWidget {
  const _PinLoginTab({Key? key}) : super(key: key);
  @override
  State<_PinLoginTab> createState() => _PinLoginTabState();
}

class _PinLoginTabState extends State<_PinLoginTab> {
  final _pinCtrl = TextEditingController();
  String? _rawPhone;
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
        final jwt = jsonDecode(resp.body)['token'];
        await SharedPreferences.getInstance().then((p) => p.setString('token', jwt));
        if (context.mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DiagnoseScreen()));
        }
      } else {
        setState(() => _error = jsonDecode(resp.body)['error'] ?? 'PIN login failed');
      }
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext c) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          IntlPhoneField(
            decoration: const InputDecoration(labelText: 'Phone Number'),
            initialCountryCode: 'KE',
            onChanged: (p) => _rawPhone = p.completeNumber,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pinCtrl,
            decoration: const InputDecoration(labelText: 'Enter PIN'),
            keyboardType: TextInputType.number,
            maxLength: 4,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _loginWithPin,
            child: _loading
                ? const CircularProgressIndicator(color: Colors.white)
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

// ───────────────────────────────────────────────────────────────────────────────
// 4) RESET PIN → OTP → New PIN → /auth/phone/reset-pin
// ───────────────────────────────────────────────────────────────────────────────
class _ResetPinTab extends StatefulWidget {
  const _ResetPinTab({Key? key}) : super(key: key);
  @override
  State<_ResetPinTab> createState() => _ResetPinTabState();
}

class _ResetPinTabState extends State<_ResetPinTab> {
  final _otpCtrl       = TextEditingController();
  final _newPinCtrl    = TextEditingController();
  final _confirmPinCtrl= TextEditingController();
  String? _rawPhone;
  String? _verificationId;
  int?    _resendToken;
  bool   _otpSent    = false;
  bool   _loading    = false;
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
      verificationCompleted: (cred) async {},
      verificationFailed: (e) => setState(() => _error = e.message),
      codeSent: (vid, tok) => setState(() {
        _verificationId = vid;
        _resendToken   = tok;
        _otpSent       = true;
      }),
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
      final cred   = PhoneAuthProvider.credential(
          verificationId: _verificationId!, smsCode: otp);
      final uc     = await FirebaseAuth.instance.signInWithCredential(cred);
      final idToken= await uc.user?.getIdToken();

      final resp = await http.post(
        Uri.parse('$backendBaseURL/auth/phone/reset-pin'),  // 📍 phone/reset-pin
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_token': idToken, 'new_pin': newPin}),
      );

      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ PIN updated!'))
        );
        setState(() {
          _otpSent = false;
          _otpCtrl.clear();
          _newPinCtrl.clear();
          _confirmPinCtrl.clear();
        });
      } else {
        setState(() => _error = jsonDecode(resp.body)['error'] ?? 'Reset failed');
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
              decoration: const InputDecoration(labelText: 'Phone Number'),
              initialCountryCode: 'KE',
              onChanged: (p) => _rawPhone = p.completeNumber,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _sendOtp,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Send OTP'),
            ),
          ] else ...[
            TextField(
              controller: _otpCtrl,
              decoration: const InputDecoration(labelText: '6-digit OTP'),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPinCtrl,
              decoration: const InputDecoration(labelText: 'New 4-digit PIN'),
              keyboardType: TextInputType.number,
              maxLength: 4,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPinCtrl,
              decoration: const InputDecoration(labelText: 'Confirm PIN'),
              keyboardType: TextInputType.number,
              maxLength: 4,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _verifyAndReset,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Reset PIN'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loading ? null : _sendOtp,
              child: const Text('Resend OTP'),
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