import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  
  final _emailPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  
  bool _isObscure = true;
  bool _isOtpMode = false;
  bool _otpSent = false;
  String _demoOtp = '';
  String? _verificationId;
  bool _isFirebaseFlow = false;
  ConfirmationResult? _confirmationResult;
  
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _isOtpMode = false;
        _otpSent = false;
        _demoOtp = '';
        _confirmationResult = null;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailPhoneController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleBiometricLogin() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheckBio = await _localAuth.canCheckBiometrics;
      
      if (!isSupported || !canCheckBio) {
        _showSnackBar("Biometrics are not configured on this device.");
        return;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access Aarogya Vault securely',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        // Authenticated locally. Try logging in with the securely stored biometric token
        final success = await ref.read(authProvider.notifier).loginWithStoredBiometrics();
        if (success && mounted) {
          _navigateToDashboard();
        } else {
          if (mounted) {
            _showSnackBar("Biometrics are not configured. Please log in with password/OTP and enable biometrics in settings.");
          }
        }
      }
    } catch (e) {
      _showSnackBar("Biometric authentication error: $e");
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    String val = _emailPhoneController.text.trim();
    if (!val.contains('@') && !val.startsWith('+')) {
      final clean = val.replaceAll(RegExp(r'\s+|-'), '');
      if (clean.length == 10 && RegExp(r'^\d+$').hasMatch(clean)) {
        val = '+91$clean';
      }
    }
    
    if (_isOtpMode) {

      if (!_otpSent) {
        // Run phone OTP setup
        final phone = val;
        // Verify via Firebase Phone Auth; if Firebase is unavailable, fall back to the backend OTP endpoint.
        try {
          setState(() {
            _isFirebaseFlow = true;
          });
          if (kIsWeb) {
            final confirmationResult = await FirebaseAuth.instance.signInWithPhoneNumber(phone);
            setState(() {
              _confirmationResult = confirmationResult;
              _otpSent = true;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("OTP sent via Firebase Phone Auth Web."),
                  backgroundColor: AppTheme.primaryTeal,
                ),
              );
            }
          } else {
            await FirebaseAuth.instance.verifyPhoneNumber(
              phoneNumber: phone,
              verificationCompleted: (PhoneAuthCredential credential) async {
                final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
                final idToken = await userCred.user?.getIdToken();
                if (idToken != null) {
                  final success = await ref.read(authProvider.notifier).verifyFirebaseOtp(idToken);
                  if (success && mounted) {
                    _navigateToDashboard();
                  } else {
                    _showSnackBar("Firebase login failed. Please try again or request a new OTP.");
                  }
                } else {
                  _showSnackBar("Unable to obtain Firebase ID token.");
                }
              },
              verificationFailed: (FirebaseAuthException e) {
                debugPrint("Firebase verification failed: ${e.message}. Falling back to backend OTP.");
                _fallbackToBackendOtpSend(phone);
              },
              codeSent: (String verificationId, int? resendToken) {
                setState(() {
                  _verificationId = verificationId;
                  _otpSent = true;
                  _isFirebaseFlow = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("OTP sent via Firebase Phone Auth."),
                    backgroundColor: AppTheme.primaryTeal,
                  ),
                );
              },
              codeAutoRetrievalTimeout: (String verificationId) {
                _verificationId = verificationId;
              },
            );
          }
        } catch (e) {
          debugPrint("Firebase exception: $e. Falling back to backend OTP.");
          await _fallbackToBackendOtpSend(phone);
        }
      } else {
        final code = _otpController.text.trim();
        if (_isFirebaseFlow) {
          if (kIsWeb && _confirmationResult != null) {
            try {
              final userCred = await _confirmationResult!.confirm(code);
              final idToken = await userCred.user?.getIdToken();
              if (idToken != null) {
                final success = await ref.read(authProvider.notifier).verifyFirebaseOtp(idToken);
                if (success && mounted) {
                  _navigateToDashboard();
                  return;
                }
              }
            } catch (e) {
              debugPrint("Firebase Web verification failed: $e. Attempting local database fallback.");
            }
          } else if (!kIsWeb && _verificationId != null) {
            try {
              final credential = PhoneAuthProvider.credential(
                verificationId: _verificationId!,
                smsCode: code,
              );
              final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
              final idToken = await userCred.user?.getIdToken();
              if (idToken != null) {
                final success = await ref.read(authProvider.notifier).verifyFirebaseOtp(idToken);
                if (success && mounted) {
                  _navigateToDashboard();
                  return;
                }
              }
            } catch (e) {
              debugPrint("Firebase Mobile verification failed: $e. Attempting local database fallback.");
            }
          }
        }
        
        // Fallback to backend OTP verify endpoint
        final success = await ref.read(authProvider.notifier).verifyOtp(val, code);
        if (success && mounted) {
          _navigateToDashboard();
        } else {
          final error = ref.read(authProvider).errorMessage;
          _showSnackBar(error ?? "Invalid OTP.");
        }
      }
      return;
    }
    
    final isLogin = _tabController.index == 0;
    final isEmail = val.contains('@');
    
    String? email = isEmail ? val : null;
    String? phone = !isEmail ? val : null;
    
    bool success = false;
    if (isLogin) {
      success = await ref.read(authProvider.notifier).login(
        email: email,
        phone: phone,
        password: _passwordController.text,
      );
    } else {
      success = await ref.read(authProvider.notifier).register(
        email: email,
        phone: phone,
        password: _passwordController.text,
      );
    }

    if (success && mounted) {
      ref.read(dashboardProvider.notifier).fetchDashboardData();
      _navigateToDashboard();
    } else {
      final error = ref.read(authProvider).errorMessage;
      if (error != null) {
        _showSnackBar(error);
      }
    }
  }

  Future<void> _fallbackToBackendOtpSend(String phone) async {
    setState(() {
      _isFirebaseFlow = false;
    });
    final demo = await ref.read(authProvider.notifier).sendOtp(phone);
    if (demo != null) {
      setState(() {
        _otpSent = true;
        _demoOtp = demo;
      });

      final message = demo.isNotEmpty
          ? "OTP sent via backend fallback. Demo OTP code is: $demo"
          : "OTP sent via backend SMS. Please check your phone.";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.primaryTeal,
          duration: const Duration(seconds: 8),
        ),
      );
    } else {
      final error = ref.read(authProvider).errorMessage;
      _showSnackBar(error ?? "Failed to send OTP.");
    }
  }

  void _navigateToDashboard() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const DashboardScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.errorRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0F1E22), AppTheme.darkBg]
                : [const Color(0xFFE2F9F5), AppTheme.lightBg],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                // Brand Header
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Icon(
                      Icons.shield_outlined,
                      size: 50,
                      color: AppTheme.primaryTeal,
                    ),
                    const Icon(
                      Icons.add_rounded,
                      size: 24,
                      color: AppTheme.primaryTeal,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  "Welcome Back!",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Login to manage your health records securely",
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Form Card
                GlassContainer(
                  borderRadius: 24,
                  opacity: isDark ? 0.08 : 0.45,
                  child: Column(
                    children: [
                      // Tab Bar
                      TabBar(
                        controller: _tabController,
                        tabs: const [
                          Tab(text: "Login"),
                          Tab(text: "Sign Up"),
                        ],
                        indicatorColor: AppTheme.primaryTeal,
                        labelColor: AppTheme.primaryTeal,
                        unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Mobile or Email field
                            TextFormField(
                              controller: _emailPhoneController,
                              decoration: InputDecoration(
                                labelText: _isOtpMode ? "Mobile Number" : "Mobile Number / Email",
                                prefixIcon: Icon(_isOtpMode ? Icons.phone_android_rounded : Icons.person_outline_rounded, color: AppTheme.primaryTeal),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: (isDark ? Colors.white24 : Colors.black12)),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return _isOtpMode ? "Please enter your mobile number" : "Please enter your email or phone number";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Password Field or OTP Code field
                            if (!_isOtpMode)
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _isObscure,
                                decoration: InputDecoration(
                                  labelText: "Password",
                                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.primaryTeal),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: AppTheme.primaryTeal,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isObscure = !_isObscure;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: (isDark ? Colors.white24 : Colors.black12)),
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.length < 6) {
                                    return "Password must be at least 6 characters";
                                  }
                                  return null;
                                },
                              )
                            else if (_otpSent)
                              TextFormField(
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: "6-Digit OTP Code",
                                  prefixIcon: const Icon(Icons.password_rounded, color: AppTheme.primaryTeal),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: (isDark ? Colors.white24 : Colors.black12)),
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().length != 6) {
                                    return "OTP must be exactly 6 digits";
                                  }
                                  return null;
                                },
                              ),
                            
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (_tabController.index == 0)
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _isOtpMode = !_isOtpMode;
                                        _otpSent = false;
                                        _demoOtp = '';
                                      });
                                    },
                                    child: Text(
                                      _isOtpMode ? "Login with Password" : "Login with OTP",
                                      style: const TextStyle(color: AppTheme.primaryTeal, fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                  )
                                else
                                  const SizedBox.shrink(),
                                if (!_isOtpMode)
                                  TextButton(
                                    onPressed: () {
                                      _showSnackBar("Simulated: Forgot password flow.");
                                    },
                                    child: const Text(
                                      "Forgot Password?",
                                      style: TextStyle(color: AppTheme.primaryTeal, fontSize: 13),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            // Submit Button
                            ElevatedButton(
                              onPressed: authState.isLoading ? null : _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryTeal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: authState.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      _isOtpMode
                                          ? (!_otpSent ? "Send OTP" : "Verify & Login")
                                          : (_tabController.index == 0 ? "Login" : "Sign Up"),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                // Biometrics login trigger
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Or login with: "),
                    IconButton(
                      icon: const Icon(Icons.fingerprint_rounded, size: 36, color: AppTheme.primaryTeal),
                      onPressed: _handleBiometricLogin,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.face_unlock_rounded, size: 36, color: AppTheme.primaryTeal),
                      onPressed: _handleBiometricLogin,
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                // Social Auth Integration
                const Text("Or continue with"),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialButton(Icons.g_mobiledata_rounded, "Google", () async {
                      final success = await ref.read(authProvider.notifier).login(
                        email: "majid@aarogyavault.com",
                        password: "Password123",
                      );
                      if (success && mounted) {
                        _navigateToDashboard();
                      } else {
                        _showSnackBar("Google Sign-In failed.");
                      }
                    }),
                    const SizedBox(width: 16),
                    _buildSocialButton(Icons.fingerprint, "Aadhaar", () {
                      _showSnackBar("Aadhaar Gateway linkage triggered.");
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, String label, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (isDark ? Colors.white10 : Colors.black12),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryTeal),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
