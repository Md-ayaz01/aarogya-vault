import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/database/local_db.dart';

class OTPScreen extends StatefulWidget {
  final String phone;
  final String? verificationId;
  const OTPScreen({Key? key, required this.phone, this.verificationId}) : super(key: key);

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final apiClient = getIt<ApiClient>();
    final code = _codeController.text.trim();

    try {
      String token;
      String role;
      int userId;

      if (widget.verificationId != null) {
        final credential = PhoneAuthProvider.credential(
          verificationId: widget.verificationId!,
          smsCode: code,
        );
        final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
        final idToken = await userCred.user?.getIdToken();
        if (idToken == null) {
          throw Exception("Verification failed: no ID token returned from Firebase.");
        }

        final response = await apiClient.post('/auth/verify-firebase-otp', data: {
          'id_token': idToken,
        });

        role = response.data['role'] as String? ?? 'doctor';
        if (role != 'doctor') {
          throw Exception("Access Denied: You do not have doctor privileges.");
        }

        token = response.data['access_token'] as String;
        userId = response.data['user_id'] as int;
      } else {
        final response = await apiClient.post('/auth/verify-otp', data: {
          'phone': widget.phone,
          'code': code
        });

        role = response.data['role'] as String? ?? 'doctor';
        if (role != 'doctor') {
          throw Exception("Access Denied: You do not have doctor privileges.");
        }

        token = response.data['access_token'] as String;
        userId = response.data['user_id'] as int;
      }

      await LocalDB.saveToken(token);
      await LocalDB.saveRole(role);
      await LocalDB.save(LocalDB.keyUserId, userId);

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
      }
    } catch (e) {
      setState(() {
        if (e is DioException) {
          _errorMessage = e.response?.data['detail'] ?? "Invalid OTP code. Please try again.";
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
      appBar: AppBar(
        title: const Text('OTP Verification'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Enter Verification Code',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We have sent a 6-digit code to ${widget.phone}. Local dev OTP is 123456.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 32),
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
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: '6-Digit OTP Code',
                    prefixIcon: Icon(Icons.security_rounded),
                    hintText: '123456',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Verification code is required';
                    if (val.trim().length != 6) return 'Code must be 6 digits';
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _verifyOtp,
                        child: const Text('Verify and Sign In'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
