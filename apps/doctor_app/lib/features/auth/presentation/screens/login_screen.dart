import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/database/local_db.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isPasswordLogin = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final apiClient = getIt<ApiClient>();

    try {
      if (_isPasswordLogin) {
        // Email/Password login
        final response = await apiClient.post('/auth/login', data: {
          'email': _emailController.text.trim(),
          'password': _passwordController.text
        });

        final role = response.data['role'] as String?;
        if (role != 'doctor') {
          throw Exception("Access Denied: You do not have doctor privileges.");
        }

        final token = response.data['access_token'] as String;
        await LocalDB.saveToken(token);
        await LocalDB.saveRole(role ?? 'doctor');

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } else {
        // OTP Login request - Firebase Auth flow
        final phone = _phoneController.text.trim();
        try {
          await FirebaseAuth.instance.verifyPhoneNumber(
            phoneNumber: phone,
            verificationCompleted: (PhoneAuthCredential credential) async {
              final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
              final idToken = await userCred.user?.getIdToken();
              if (idToken != null) {
                final response = await apiClient.post('/auth/verify-firebase-otp', data: {
                  'id_token': idToken,
                });
                final role = response.data['role'] as String?;
                if (role != 'doctor') {
                  throw Exception("Access Denied: You do not have doctor privileges.");
                }
                final token = response.data['access_token'] as String;
                await LocalDB.saveToken(token);
                await LocalDB.saveRole(role ?? 'doctor');
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/dashboard');
                }
              }
            },
            verificationFailed: (FirebaseAuthException e) {
              setState(() {
                _errorMessage = "Firebase OTP failed: ${e.message}.";
              });
            },
            codeSent: (String verificationId, int? resendToken) {
              if (mounted) {
                Navigator.pushNamed(
                  context, 
                  '/otp', 
                  arguments: {
                    'phone': phone,
                    'verificationId': verificationId,
                  }
                );
              }
            },
            codeAutoRetrievalTimeout: (String verificationId) {},
          );
        } catch (e) {
          // Dev local fallback
          await apiClient.post('/auth/send-otp', data: {'phone': phone});
          if (mounted) {
            Navigator.pushNamed(context, '/otp', arguments: {'phone': phone});
          }
        }
      }
    } catch (e) {
      setState(() {
        if (e is DioException) {
          _errorMessage = e.response?.data['detail'] ?? "Login failed. Please check credentials.";
        } else {
          _errorMessage = e.toString().replaceFirst("Exception: ", "");
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Icon(
                  Icons.local_hospital_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Aarogya Vault',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ),
              Center(
                child: Text(
                  'Clinical Portal for Doctors',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              const SizedBox(height: 48),
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onErrorContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_isPasswordLogin) ...[
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Email is required';
                          if (!val.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outlined),
                        ),
                        obscureText: true,
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Password is required';
                          return null;
                        },
                      ),
                    ] else ...[
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Mobile Number',
                          prefixIcon: Icon(Icons.phone_outlined),
                          hintText: '+919999988888',
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Phone number is required';
                          if (!val.startsWith('+')) return 'Include country code (e.g. +91)';
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 32),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _handleLogin,
                            child: Text(_isPasswordLogin ? 'Sign In' : 'Send OTP Verification'),
                          ),
                    const SizedBox(height: 24),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _isPasswordLogin = !_isPasswordLogin;
                            _errorMessage = null;
                          });
                        },
                        child: Text(
                          _isPasswordLogin
                              ? 'Login with Mobile Phone OTP'
                              : 'Login with Email / Password',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
