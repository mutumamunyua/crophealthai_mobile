import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:shared_preferences/shared_preferences.dart'; // CORRECTED THIS LINE
import 'package:http/http.dart' as http;

import '../config.dart';          // for backendBaseURL
import 'diagnose_screen.dart';    // navigate on success

const Color kPhoneBackground = Color(0xFFE8F5E9);
const Color kPhoneBackgroundLighter = Color(0xFFF0F9F0); // Slightly lighter
const Color kPhoneBackgroundDarker = Color(0xFFDCEADD); // Slightly darker

//==============================================================================
// MAIN AUTHENTICATION SCREEN (ENTRY POINT)
//==============================================================================

class PhoneRegistrationScreen extends StatelessWidget {
  const PhoneRegistrationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // The default screen is now the LoginPage.
    // Register and Reset PIN are separate pages navigated to from here.
    return const LoginPage();
  }
}

//==============================================================================
// 1. PHONE LOGIN PAGE
//==============================================================================

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? _rawPhone;
  final _pinCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  /// Handles the login logic by calling the backend.
  Future<void> _loginWithPin() async {
    final pin = _pinCtrl.text.trim();
    if (_rawPhone == null || pin.length != 4) {
      setState(() => _error = 'Phone & 4-digit PIN required');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

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
        //setState(() => _error = resp.body);
      }
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue.shade50,
      body: Container(
        // A beautiful gradient background for a modern look.
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlue.shade100, Colors.lightBlue.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header section with improved typography
                  const Text(
                    'Welcome Back',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(blurRadius: 10.0, color: Colors.black26, offset: Offset(0, 2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sign in to continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 50),

                  // The main form card with a glassmorphism effect
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        // Phone Field with updated styling
                        IntlPhoneField(
                          style: const TextStyle(color: Colors.black87),
                          decoration: _buildInputDecoration('Phone Number'),
                          dropdownTextStyle: const TextStyle(color: Colors.black87),
                          dropdownIcon: const Icon(Icons.arrow_drop_down, color: Colors.black87),
                          initialCountryCode: 'KE',
                          keyboardType: TextInputType.phone,
                          onChanged: (p) {
                            var local = p.number;
                            if (local.startsWith('0')) local = local.substring(1);
                            _rawPhone = '${p.countryCode}$local';
                          },
                        ),
                        const SizedBox(height: 16),

                        // PIN Field with updated styling
                        TextField(
                          controller: _pinCtrl,
                          obscureText: true,
                          style: const TextStyle(color: Colors.black87),
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          decoration: _buildInputDecoration('Enter PIN'),
                        ),
                        const SizedBox(height: 30),

                        // Login Button with enhanced styling
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.blue.shade900,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5,
                            ),
                            onPressed: _loading ? null : _loginWithPin,
                            child: _loading
                                ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue.shade900))
                                : const Text('LOGIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Error Message
                  if (_error != null)
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.amberAccent, fontSize: 14, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 20),

                  // Navigation Links
                  _buildNavigationLinks(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Helper to build consistent InputDecoration for text fields.
  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.black87.withOpacity(0.8)),
      counterText: '',
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.lightBlue.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.lightBlue.shade400, width: 2),
      ),
    );
  }

  /// Builds the clickable text links for navigating to other pages.
  Widget _buildNavigationLinks(BuildContext context) {
    return Column(
      children: [
        Text.rich(
          TextSpan(
            text: "Not registered? ",
            style: TextStyle(color: Colors.white.withOpacity(0.8)),
            children: [
              TextSpan(
                text: 'Register/Sign Up',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    );
                  },
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text.rich(
          TextSpan(
            text: "Forgot PIN? ",
            style: TextStyle(color: Colors.white.withOpacity(0.8)),
            children: [
              TextSpan(
                text: 'Reset here',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ResetPinPage()),
                    );
                  },
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

//==============================================================================
// 2. REGISTRATION PAGE
//==============================================================================

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  String? _rawPhone;
  String? _verificationId;
  final _pinCtrl = TextEditingController();
  final _confirmPinCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _otpSent = false, _loading = false;
  String? _error;

  /// Sends an OTP to the user's phone for verification.
  Future<void> _sendOtp() async {
    final pin = _pinCtrl.text.trim();
    final conf = _confirmPinCtrl.text.trim();
    if (_rawPhone == null || pin.length != 4 || pin != conf) {
      setState(() => _error = 'Phone & matching 4-digit PINs required');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
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
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  /// Verifies the OTP and registers the user on the backend.
  Future<void> _verifyAndRegister() async {
    final otp = _otpCtrl.text.trim();
    final pin = _pinCtrl.text.trim();
    if (otp.length != 6) {
      setState(() => _error = 'Enter a 6-digit OTP');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
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
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_otpSent ? 'Verify Phone' : 'Create Account'),
        backgroundColor: Colors.blue.shade400,
        elevation: 0,
      ),
      body: Container(
        color: Colors.lightBlue.shade50,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_otpSent) ...[
                IntlPhoneField(
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue.shade200),
                      borderRadius: BorderRadius.circular(5),
                    ),
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
                  decoration: InputDecoration(
                    labelText: 'Set PIN (4 digits)',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    counterText: '',
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue.shade200),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPinCtrl,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: InputDecoration(
                    labelText: 'Confirm PIN',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    counterText: '',
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue.shade200),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue.shade400,
                  ),
                  onPressed: _loading ? null : _sendOtp,
                  child: _loading
                      ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('SEND OTP'),
                ),
              ] else ...[
                Text("Enter the 6-digit code sent to $_rawPhone",
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 20),
                TextField(
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'Enter OTP',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    counterText: '',
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue.shade200),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue.shade400,
                  ),
                  onPressed: _loading ? null : _verifyAndRegister,
                  child: _loading
                      ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('VERIFY & REGISTER'),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

//==============================================================================
// 3. RESET PIN PAGE
//==============================================================================

/// A separate page for resetting a forgotten PIN with a clean UI.
class ResetPinPage extends StatefulWidget {
  const ResetPinPage({Key? key}) : super(key: key);
  @override
  State<ResetPinPage> createState() => _ResetPinPageState();
}

class _ResetPinPageState extends State<ResetPinPage> {
  String? _rawPhone;
  String? _verificationId;
  final _otpCtrl = TextEditingController();
  final _newPinCtrl = TextEditingController();
  final _confirmPinCtrl = TextEditingController();
  bool _otpSent = false, _loading = false;
  String? _error;

  /// Sends an OTP to the user's phone.
  Future<void> _sendOtp() async {
    if (_rawPhone == null) {
      setState(() => _error = 'Enter phone first');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

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

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  /// Verifies the OTP and resets the PIN on the backend.
  Future<void> _verifyAndReset() async {
    final otp = _otpCtrl.text.trim();
    final newPin = _newPinCtrl.text.trim();
    final conf = _confirmPinCtrl.text.trim();

    if (otp.length != 6 || newPin.length != 4 || newPin != conf) {
      setState(() => _error = 'OTP + matching 4-digit PINs required');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ PIN updated! Please login with new PIN'),
            backgroundColor: Colors.blue,
          ),
        );
        // Pop back to the Login Page
        Navigator.of(context).pop();
      } else {
        final body = jsonDecode(resp.body);
        setState(() => _error = body['error'] ?? 'Reset failed');
      }
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_otpSent ? 'Verify & Reset' : 'Reset PIN'),
        backgroundColor: Colors.blue.shade600,
        elevation: 0,
      ),
      body: Container(
        color: Colors.lightBlue.shade50,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_otpSent) ...[
                IntlPhoneField(
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue.shade200),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  initialCountryCode: 'KE',
                  keyboardType: TextInputType.phone,
                  onChanged: (p) {
                    var local = p.number;
                    if (local.startsWith('0')) local = local.substring(1);
                    _rawPhone = '${p.countryCode}$local';
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue.shade600,
                  ),
                  onPressed: _loading ? null : _sendOtp,
                  child: _loading
                      ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('SEND OTP'),
                ),
              ] else ...[
                TextField(
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'Enter OTP',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    counterText: '',
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue.shade200),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _newPinCtrl,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: InputDecoration(
                    labelText: 'New PIN',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    counterText: '',
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue.shade200),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPinCtrl,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: InputDecoration(
                    labelText: 'Confirm PIN',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    counterText: '',
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue.shade200),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue.shade600,
                  ),
                  onPressed: _loading ? null : _verifyAndReset,
                  child: _loading
                      ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('RESET PIN'),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

