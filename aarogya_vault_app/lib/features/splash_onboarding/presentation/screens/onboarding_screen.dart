import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/screens/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: "Your Complete\nHealth Companion",
      description: "Store, manage and access your health records securely. Get AI insights and emergency help in seconds.",
      mainIcon: Icons.lock_rounded,
      orbitIcon1: Icons.medical_information_rounded,
      orbitIcon2: Icons.qr_code_2_rounded,
      accentColor: AppTheme.primary,
    ),
    OnboardingPageData(
      title: "Secure Digital\nHealth Records",
      description: "Keep blood reports, prescriptions, MRI, CT scans, and vaccines in one place, protected by encryption.",
      mainIcon: Icons.shield_rounded,
      orbitIcon1: Icons.description_rounded,
      orbitIcon2: Icons.verified_user_rounded,
      accentColor: AppTheme.secondary,
    ),
    OnboardingPageData(
      title: "AI Assistant &\nEmergency QR",
      description: "Ask AI to analyze reports, set medicine reminders, and generate an offline QR code for responders.",
      mainIcon: Icons.qr_code_scanner_rounded,
      orbitIcon1: Icons.insights_rounded,
      orbitIcon2: Icons.psychology_rounded,
      accentColor: AppTheme.primary,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finishOnboarding() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _handleNext() {
    if (_currentIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.add_moderator_rounded, color: AppTheme.primary, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        "Aarogya Vault",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _finishOnboarding,
                    child: Text(
                      "Skip",
                      style: GoogleFonts.inter(
                        color: isDark ? Colors.white60 : AppTheme.outline,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Premium Orbiting central illustration
                        SizedBox(
                          width: 240,
                          height: 240,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer dashed ring
                              Container(
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark ? Colors.white10 : AppTheme.outlineVariant.withOpacity(0.3),
                                    width: 2,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                              ),

                              // Central white card
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.darkSurface : Colors.white,
                                  borderRadius: BorderRadius.circular(32),
                                  border: Border.all(
                                    color: isDark ? Colors.white10 : AppTheme.outlineVariant.withOpacity(0.3),
                                  ),
                                  boxShadow: AppTheme.premiumShadow,
                                ),
                                child: Center(
                                  child: Icon(
                                    page.mainIcon,
                                    size: 48,
                                    color: page.accentColor,
                                  ),
                                ),
                              ),

                              // Orbiting Chip 1 (Top Right)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondaryContainer,
                                    shape: BoxShape.circle,
                                    boxShadow: AppTheme.premiumShadow,
                                  ),
                                  child: Icon(
                                    page.orbitIcon1,
                                    size: 20,
                                    color: AppTheme.onSecondaryContainer,
                                  ),
                                ),
                              ),

                              // Orbiting Chip 2 (Bottom Left)
                              Positioned(
                                bottom: 12,
                                left: 12,
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                    boxShadow: AppTheme.premiumShadow,
                                  ),
                                  child: Icon(
                                    page.orbitIcon2,
                                    size: 20,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Title & Subtitle
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            height: 1.25,
                            color: isDark ? Colors.white : AppTheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            color: AppTheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Footer with indicator and next button
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Indicators
                  Row(
                    children: List.generate(_pages.length, (i) {
                      final active = _currentIndex == i;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        width: active ? 24 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: active ? AppTheme.primary : AppTheme.outlineVariant,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),

                  // Next Button
                  ElevatedButton(
                    onPressed: _handleNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shadowColor: AppTheme.primary.withOpacity(0.3),
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      // Override the global theme's Size(double.infinity, 56) which
                      // crashes when this button is inside a Row (gets w=Infinity).
                      minimumSize: const Size(0, 48),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentIndex == _pages.length - 1 ? "Done" : "Next",
                          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPageData {
  final String title;
  final String description;
  final IconData mainIcon;
  final IconData orbitIcon1;
  final IconData orbitIcon2;
  final Color accentColor;

  OnboardingPageData({
    required this.title,
    required this.description,
    required this.mainIcon,
    required this.orbitIcon1,
    required this.orbitIcon2,
    required this.accentColor,
  });
}
