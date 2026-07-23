import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/api_provider.dart';
import '../providers/dashboard_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../reports/presentation/screens/reports_screen.dart';
import '../../../ai_assistant/presentation/screens/ai_assistant_screen.dart';
import '../../../emergency_qr/presentation/screens/emergency_qr_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../ayushman/presentation/screens/ayushman_screen.dart';
import '../../../medical_history/presentation/screens/medical_history_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  late final AnimationController _waveController;
  late final Animation<double> _waveAnim;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _waveAnim = CurvedAnimation(parent: _waveController, curve: Curves.easeInOut);

    Future.microtask(() {
      ref.read(dashboardProvider.notifier).loadDashboard();
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    // Prevent startup layout crashes when Flutter Web reports 0 or tiny width initially
    if (MediaQuery.of(context).size.width < 100) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    final state = ref.watch(dashboardProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: colorScheme.surface,
        drawer: _buildDrawer(),
        body: SafeArea(
          child: RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: () async {
              await ref.read(dashboardProvider.notifier).loadDashboard();
            },
            child: CustomScrollView(
              slivers: [
                // ── App Bar ──────────────────────────────────────────────
                SliverToBoxAdapter(child: _buildAppBar(state, isDark)),
                // ── Body ─────────────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 8),
                      _buildGreeting(state),
                      const SizedBox(height: 20),
                      _buildSearchBar(),
                      const SizedBox(height: 28),
                      _buildHealthScoreCard(state),
                      const SizedBox(height: 28),
                      _buildSectionHeader('Quick Access'),
                      const SizedBox(height: 16),
                      _buildBentoGrid(),
                      const SizedBox(height: 28),
                      _buildSectionHeader(
                        'Upcoming Today', 
                        showAll: true,
                        onViewAll: () => Navigator.pushNamed(context, '/reminders'),
                      ),
                      const SizedBox(height: 16),
                      _buildRemindersSection(state),
                      const SizedBox(height: 28),
                      _buildEmergencyBanner(),
                      const SizedBox(height: 100), // nav bar clearance
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildFloatingNavBar(),
        floatingActionButton: _buildFAB(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  // ── App Bar ──────────────────────────────────────────────────────────────────
  Widget _buildAppBar(DashboardState state, bool isDark) {
    return Container(
      color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: Icon(Icons.menu, size: 28, color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(width: 16),
          Text(
            'Aarogya Vault',
            style: GoogleFonts.inter(
              fontSize: 20, fontWeight: FontWeight.w700,
              color: AppTheme.primary, letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          // Notification bell
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_outlined,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                onPressed: () => _showNotificationsBottomSheet(context),
              ),
              Positioned(
                top: 10, right: 10,
                child: Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.error,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface, width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          // Profile avatar
          GestureDetector(
            onTap: () => _navigateTo(const ProfileScreen()),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primary.withOpacity(0.15), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8, offset: const Offset(0, 2),
                  )
                ],
                gradient: const LinearGradient(
                  colors: [Color(0xFF7AD5D5), Color(0xFF005F5F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0F1E2E) : Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF006A6A), Color(0xFF004F4F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 40),
                const SizedBox(height: 12),
                Text(
                  'Aarogya Vault',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Your Health. Your Data.',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_rounded, color: AppTheme.primary),
            title: const Text('My Profile'),
            onTap: () {
              Navigator.pop(context);
              _navigateTo(const ProfileScreen());
            },
          ),
          ListTile(
            leading: const Icon(Icons.description_rounded, color: AppTheme.primary),
            title: const Text('Lab Reports'),
            onTap: () {
              Navigator.pop(context);
              _navigateTo(const ReportsScreen());
            },
          ),
          ListTile(
            leading: const Icon(Icons.history_edu_rounded, color: AppTheme.primary),
            title: const Text('Medical History'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/medical_history');
            },
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primary),
            title: const Text('Emergency QR'),
            onTap: () {
              Navigator.pop(context);
              _navigateTo(const EmergencyQRScreen());
            },
          ),
          ListTile(
            leading: const Icon(Icons.smart_toy_rounded, color: AppTheme.primary),
            title: const Text('AI Health Doc'),
            onTap: () {
              Navigator.pop(context);
              _navigateTo(const AiAssistantScreen());
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_rounded, color: AppTheme.primary),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text('Logout'),
            onTap: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/splash');
              }
            },
          ),
        ],
      ),
    );
  }

  // ── Greeting ─────────────────────────────────────────────────────────────────
  Widget _buildGreeting(DashboardState state) {
    final name = state.profile?.fullName.split(' ').first ?? 'there';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Hello, $name ',
              style: GoogleFonts.inter(
                fontSize: 36, fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            AnimatedBuilder(
              animation: _waveAnim,
              builder: (_, __) => Transform.rotate(
                angle: (_waveAnim.value - 0.5) * 0.4,
                origin: const Offset(8, 16),
                child: const Text('👋', style: TextStyle(fontSize: 36)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Ready for your health check-up today?',
          style: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // ── Search Bar ────────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/search'),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface == AppTheme.surface
              ? Colors.white
              : const Color(0xFF1A2E45),
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.premiumShadow,
        ),
        child: TextField(
          enabled: false,
          decoration: InputDecoration(
            hintText: 'Search medical records, labs...',
            hintStyle: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.7),
              fontSize: 14,
            ),
            prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.outline),
            suffixIcon: Icon(Icons.mic_none_rounded,
                color: Theme.of(context).colorScheme.outline, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ),
    );
  }

  // ── Health Score Hero Card ────────────────────────────────────────────────────
  Widget _buildHealthScoreCard(DashboardState state) {
    final score = state.profile?.healthScore ?? 92;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF006A6A), Color(0xFF004F4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF006A6A).withOpacity(0.40),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Ambient blobs
            Positioned(
              right: -48, top: -48,
              child: Container(
                width: 220, height: 220,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: -32, bottom: -32,
              child: Container(
                width: 140, height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFF7AD5D5).withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Score text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DAILY HEALTH SCORE',
                              style: GoogleFonts.inter(
                                fontSize: 11, fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                                color: const Color(0xFFACFFFE).withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '$score',
                                  style: GoogleFonts.inter(
                                    fontSize: 60, fontWeight: FontWeight.w800,
                                    color: Colors.white, letterSpacing: -2,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '%',
                                  style: GoogleFonts.inter(
                                    fontSize: 24, fontWeight: FontWeight.w500,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.1)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.verified_rounded,
                                      size: 16,
                                      color: Color(0xFF6CF8BB)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Excellent Status',
                                    style: GoogleFonts.inter(
                                      fontSize: 12, fontWeight: FontWeight.w700,
                                      color: const Color(0xFF6CF8BB),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Circular gauge
                      SizedBox(
                        width: 112, height: 112,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: score / 100),
                              duration: const Duration(milliseconds: 1200),
                              curve: Curves.easeOutCubic,
                              builder: (_, value, __) => CustomPaint(
                                size: const Size(112, 112),
                                painter: _GaugePainter(progress: value),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.05)),
                              ),
                              child: const Icon(
                                Icons.health_and_safety_rounded,
                                color: Colors.white, size: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Divider(color: Colors.white.withOpacity(0.12), height: 1),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _healthBadge(Icons.favorite_rounded),
                      Transform.translate(
                        offset: const Offset(-8, 0),
                        child: _healthBadge(Icons.bolt_rounded),
                      ),
                      Transform.translate(
                        offset: const Offset(-16, 0),
                        child: _healthBadge(Icons.self_improvement_rounded),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _navigateTo(const AiAssistantScreen()),
                        child: Row(
                          children: [
                            Text(
                              'Insights',
                              style: GoogleFonts.inter(
                                fontSize: 12, fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_rounded,
                                color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _healthBadge(IconData icon) {
    return Container(
      width: 34, height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.surfaceContainerHigh,
        border: Border.all(color: AppTheme.primary, width: 2),
      ),
      child: Icon(icon, size: 16, color: AppTheme.primary),
    );
  }

  // ── Section Header ────────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, {bool showAll = false, VoidCallback? onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 20, fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        if (showAll)
          GestureDetector(
            onTap: onViewAll,
            child: Row(
              children: [
                Text(
                  'View All',
                  style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right, color: AppTheme.primary, size: 16),
              ],
            ),
          ),
      ],
    );
  }

  // ── Bento Quick Actions Grid ──────────────────────────────────────────────────
  Widget _buildBentoGrid() {
    final actions = [
      _BentoAction(
        label: 'Profile', icon: Icons.person_rounded,
        bgColor: const Color(0xFFEFF6FF), iconColor: const Color(0xFF2563EB),
        onTap: () => _navigateTo(const ProfileScreen()),
      ),
      _BentoAction(
        label: 'History', icon: Icons.history_edu_rounded,
        bgColor: const Color(0xFFF0FDF4), iconColor: const Color(0xFF16A34A),
        onTap: () => Navigator.pushNamed(context, '/medical_history'),
      ),
      _BentoAction(
        label: 'Reports', icon: Icons.description_rounded,
        bgColor: const Color(0xFFF5F3FF), iconColor: const Color(0xFF7C3AED),
        onTap: () => _navigateTo(const ReportsScreen()),
      ),
      _BentoAction(
        label: 'E-QR', icon: Icons.qr_code_scanner_rounded,
        bgColor: AppTheme.tertiary, iconColor: Colors.white,
        solidBg: true,
        onTap: () => _navigateTo(const EmergencyQRScreen()),
      ),
      _BentoAction(
        label: 'AI Doc', icon: Icons.smart_toy_rounded,
        bgColor: const Color(0xFFF0FDFA), iconColor: const Color(0xFF0D9488),
        onTap: () => _navigateTo(const AiAssistantScreen()),
      ),
      _BentoAction(
        label: 'Appts', icon: Icons.calendar_today_rounded,
        bgColor: const Color(0xFFFFFBEB), iconColor: const Color(0xFFD97706),
        onTap: () => Navigator.pushNamed(context, '/find_specialists'),
      ),
      _BentoAction(
        label: 'Meds', icon: Icons.medication_rounded,
        bgColor: const Color(0xFFFFF1F2), iconColor: const Color(0xFFE11D48),
        onTap: () => Navigator.pushNamed(context, '/reminders'),
      ),
      _BentoAction(
        label: 'More', icon: Icons.grid_view_rounded,
        bgColor: const Color(0xFFF8FAFC), iconColor: const Color(0xFF475569),
        onTap: () => _showAllActionsBottomSheet(context),
      ),
    ];

    return GridView.count(
      crossAxisCount: 4,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.78,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: actions.map((a) => _BentoTile(action: a)).toList(),
    );
  }

  // ── Reminders Section ─────────────────────────────────────────────────────────
  Widget _buildRemindersSection(DashboardState state) {
    if (state.isLoading) {
      return Column(
        children: List.generate(2, (_) => _buildReminderSkeleton()),
      );
    }

    final reminders = state.reminders;
    final appointments = state.appointments;

    if (reminders.isEmpty && appointments.isEmpty) {
      return _buildEmptyReminders();
    }

    return Column(
      children: [
        ...reminders.take(2).map((r) => _buildReminderCard(
          icon: Icons.alarm_rounded,
          iconBgColor: AppTheme.secondaryContainer.withOpacity(0.15),
          iconColor: AppTheme.secondary,
          title: '${r.medicineName} ${r.dosage}',
          subtitle: '${r.instruction} • ',
          timeStr: r.time,
          badge: '1',
          trailing: _DoneButton(),
        )),
        ...appointments.take(1).map((a) => _buildReminderCard(
          icon: Icons.medical_services,
          iconBgColor: AppTheme.primaryContainer.withOpacity(0.12),
          iconColor: AppTheme.primary,
          title: a.doctorName,
          subtitle: '${a.specialty ?? ''} • ',
          timeStr: a.dateTime.split(' ').last,
          trailing: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppTheme.outline),
          ),
        )),
      ],
    );
  }

  Widget _buildReminderCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    String timeStr = '',
    String? badge,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF1A2E45),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.premiumShadow,
        border: Border.all(color: Colors.transparent),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 26, color: iconColor),
              ),
              if (badge != null)
                Positioned(
                  top: -4, right: -4,
                  child: Container(
                    width: 18, height: 18,
                    decoration: const BoxDecoration(
                      color: AppTheme.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(badge,
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                        fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    children: [
                      TextSpan(text: subtitle),
                      TextSpan(
                        text: timeStr,
                        style: GoogleFonts.inter(
                            color: AppTheme.primary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildReminderSkeleton() {
    return Shimmer.fromColors(
      baseColor: AppTheme.surfaceContainerHigh,
      highlightColor: AppTheme.surfaceContainerLowest,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 88,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildEmptyReminders() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF1A2E45),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: Column(
        children: [
          Icon(Icons.event_available_rounded,
              size: 48, color: AppTheme.primary.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text('No events today',
              style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 4),
          Text('Your schedule is clear for today.',
              style: GoogleFonts.inter(
                  fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  // ── Emergency Banner ─────────────────────────────────────────────────────────
  Widget _buildEmergencyBanner() {
    return PulsingSOSBanner(
      onTap: () => _navigateTo(const EmergencyQRScreen()),
    );
  }

  // ── Floating Navigation Bar ───────────────────────────────────────────────────
  Widget _buildFloatingNavBar() {
    final items = [
      _NavItem(Icons.home_rounded, 'Home'),
      _NavItem(Icons.folder_open_rounded, 'Vault'),
      _NavItem(Icons.forum_rounded, 'Chat'),
      _NavItem(Icons.insights_rounded, 'Stats'),
      _NavItem(Icons.account_circle_rounded, 'User'),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      height: 72,
      decoration: BoxDecoration(
        color: AppTheme.inverseSurface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 30, offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final active = _selectedIndex == i;
          return GestureDetector(
            onTap: () async {
              setState(() {
                _selectedIndex = i;
              });
              if (i == 0) return;
              Widget? target;
              if (i == 1) target = const ReportsScreen();
              if (i == 2) target = const AiAssistantScreen();
              if (i == 3) target = const MedicalHistoryScreen();
              if (i == 4) target = const ProfileScreen();
              if (target != null) {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => target!));
                if (mounted) {
                  setState(() {
                    _selectedIndex = 0;
                  });
                }
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: active
                  ? BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                    )
                  : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    items[i].icon,
                    size: 26,
                    color: active
                        ? AppTheme.primaryFixedDim
                        : Colors.white.withOpacity(0.4),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    items[i].label,
                    style: GoogleFonts.inter(
                      fontSize: 9, fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: active
                          ? AppTheme.primaryFixedDim
                          : Colors.white.withOpacity(0.4),
                    ),
                  ),
                  if (active)
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      width: 4, height: 4,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryFixedDim,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── FAB ──────────────────────────────────────────────────────────────────────
  Widget _buildFAB() {
    return Container(
      margin: const EdgeInsets.only(bottom: 80),
      child: FloatingActionButton(
        onPressed: () => _navigateTo(const ReportsScreen()),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 8,
        child: const Icon(Icons.add_rounded, size: 30),
      ),
    );
  }

  void _showNotificationsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _NotificationsBottomSheet(),
    );
  }

  void _showAllActionsBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F1E2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 40,
              offset: const Offset(0, -10),
            )
          ],
        ),
        padding: EdgeInsets.only(
          top: 20,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'All Shortcuts & Services',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.8,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildActionShortcut(
                    context: context,
                    label: 'Profile',
                    icon: Icons.person_rounded,
                    color: const Color(0xFF2563EB),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/profile');
                    },
                  ),
                  _buildActionShortcut(
                    context: context,
                    label: 'History',
                    icon: Icons.history_edu_rounded,
                    color: const Color(0xFF16A34A),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/medical_history');
                    },
                  ),
                  _buildActionShortcut(
                    context: context,
                    label: 'Reports',
                    icon: Icons.description_rounded,
                    color: const Color(0xFF7C3AED),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/reports');
                    },
                  ),
                  _buildActionShortcut(
                    context: context,
                    label: 'Emergency QR',
                    icon: Icons.qr_code_scanner_rounded,
                    color: AppTheme.tertiary,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/emergency_qr');
                    },
                  ),
                  _buildActionShortcut(
                    context: context,
                    label: 'AI Health Doc',
                    icon: Icons.smart_toy_rounded,
                    color: const Color(0xFF0D9488),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/ai_assistant');
                    },
                  ),
                  _buildActionShortcut(
                    context: context,
                    label: 'Medicine Reminders',
                    icon: Icons.medication_rounded,
                    color: const Color(0xFFE11D48),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/reminders');
                    },
                  ),
                  _buildActionShortcut(
                    context: context,
                    label: 'Ayushman PM-JAY',
                    icon: Icons.card_membership_rounded,
                    color: Colors.teal,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/ayushman');
                    },
                  ),
                  _buildActionShortcut(
                    context: context,
                    label: 'Find Specialists',
                    icon: Icons.search_rounded,
                    color: const Color(0xFFD97706),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/find_specialists');
                    },
                  ),
                  _buildActionShortcut(
                    context: context,
                    label: 'My Prescriptions',
                    icon: Icons.receipt_long_rounded,
                    color: AppTheme.primaryTeal,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/prescriptions');
                    },
                  ),
                  _buildActionShortcut(
                    context: context,
                    label: 'Settings',
                    icon: Icons.settings_rounded,
                    color: const Color(0xFF475569),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/settings');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionShortcut({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.03) : color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.05) : color.withOpacity(0.12),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isDark ? color.withOpacity(0.15) : color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class PulsingSOSBanner extends StatefulWidget {
  final VoidCallback onTap;
  const PulsingSOSBanner({Key? key, required this.onTap}) : super(key: key);

  @override
  State<PulsingSOSBanner> createState() => _PulsingSOSBannerState();
}

class _PulsingSOSBannerState extends State<PulsingSOSBanner> with SingleTickerProviderStateMixin {
  late final AnimationController _pulsingController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulsingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulsingController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulsingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.errorContainer.withOpacity(0.55),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppTheme.error.withOpacity(0.2 + (_pulsingController.value * 0.3)),
              width: 1.5 + (_pulsingController.value * 1.5),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.error.withOpacity(0.12 * _pulsingController.value),
                blurRadius: 16 * _pulseAnim.value,
                spreadRadius: 2 * _pulseAnim.value,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Transform.scale(
                scale: _pulseAnim.value,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.error,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.error.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 26),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency SOS Active',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onErrorContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap SOS to share emergency card details with responders.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.onErrorContainer.withOpacity(0.8),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: widget.onTap,
                child: Transform.scale(
                  scale: _pulseAnim.value,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.error,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.error.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'SOS',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Gauge Painter ─────────────────────────────────────────────────────────────
class _GaugePainter extends CustomPainter {
  final double progress;
  const _GaugePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final radius = (size.width - 10) / 2;
    const startAngle = -3.14159 / 2; // top

    // Track
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = Colors.white.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );

    // Arc
    final gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + 2 * 3.14159,
      colors: const [Color(0xFF97F2F1), Colors.white],
      stops: const [0.0, 1.0],
    );
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect, startAngle, 2 * 3.14159 * progress, false, paint,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.progress != progress;
}

// ── Bento Action Model ────────────────────────────────────────────────────────
class _BentoAction {
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final bool solidBg;
  final VoidCallback onTap;
  const _BentoAction({
    required this.label, required this.icon,
    required this.bgColor, required this.iconColor,
    this.solidBg = false, required this.onTap,
  });
}

class _BentoTile extends StatefulWidget {
  final _BentoAction action;
  const _BentoTile({required this.action});

  @override
  State<_BentoTile> createState() => _BentoTileState();
}

class _BentoTileState extends State<_BentoTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1, end: 0.93)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final a = widget.action;
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); a.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: a.solidBg ? a.bgColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: a.solidBg
                ? [
                    BoxShadow(
                      color: a.bgColor.withOpacity(0.25),
                      blurRadius: 12, offset: const Offset(0, 4),
                    )
                  ]
                : AppTheme.premiumShadow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: a.solidBg ? Colors.white.withOpacity(0.2) : a.bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(a.icon, size: 22, color: a.iconColor),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  a.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: a.solidBg
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

class _DoneButton extends StatefulWidget {
  @override
  State<_DoneButton> createState() => _DoneButtonState();
}

class _DoneButtonState extends State<_DoneButton> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _done = !_done),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 40, height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _done ? AppTheme.primary : Colors.transparent,
          border: Border.all(
            color: _done ? AppTheme.primary : AppTheme.outlineVariant,
            width: 2,
          ),
        ),
        child: Icon(
          _done ? Icons.check_circle_rounded : Icons.done_all_rounded,
          size: 20,
          color: _done ? Colors.white : AppTheme.outline,
        ),
      ),
    );
  }
}

class _NotificationsBottomSheet extends ConsumerStatefulWidget {
  const _NotificationsBottomSheet({Key? key}) : super(key: key);

  @override
  ConsumerState<_NotificationsBottomSheet> createState() => _NotificationsBottomSheetState();
}

class _NotificationsBottomSheetState extends ConsumerState<_NotificationsBottomSheet> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.get('/notifications');
      if (mounted) {
        setState(() {
          _notifications = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markRead(int id, int index) async {
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.patch('/notifications/$id/read');
      if (response.statusCode == 200 && mounted) {
        setState(() {
          final updated = Map<String, dynamic>.from(_notifications[index]);
          updated['is_read'] = true;
          _notifications[index] = updated;
        });
      }
    } catch (e) {
      // Ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1E2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 40,
            offset: const Offset(0, -10),
          )
        ],
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notifications',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              if (_notifications.any((n) => n['is_read'] == false))
                TextButton(
                  onPressed: () async {
                    for (int i = 0; i < _notifications.length; i++) {
                      if (_notifications[i]['is_read'] == false) {
                        await _markRead(_notifications[i]['id'], i);
                      }
                    }
                  },
                  child: Text(
                    'Mark all as read',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: _buildContent(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    if (_error != null && _notifications.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'Failed to load notifications',
            style: GoogleFonts.inter(color: AppTheme.error),
          ),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                size: 64,
                color: isDark ? Colors.white24 : Colors.black26,
              ),
              const SizedBox(height: 16),
              Text(
                'All caught up!',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'No new alerts or health reminders.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final note = _notifications[index];
        final isRead = note['is_read'] ?? false;
        final type = note['type'] ?? 'alert';
        
        IconData icon;
        Color iconColor;
        Color bgColor;

        switch (type) {
          case 'appointment':
            icon = Icons.calendar_today_rounded;
            iconColor = const Color(0xFF2563EB);
            bgColor = const Color(0xFFEFF6FF);
            break;
          case 'report':
            icon = Icons.description_rounded;
            iconColor = const Color(0xFF7C3AED);
            bgColor = const Color(0xFFF5F3FF);
            break;
          case 'reminders':
            icon = Icons.alarm_rounded;
            iconColor = const Color(0xFFE11D48);
            bgColor = const Color(0xFFFFF1F2);
            break;
          default:
            icon = Icons.notifications_active_rounded;
            iconColor = const Color(0xFFD97706);
            bgColor = const Color(0xFFFFFBEB);
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isRead 
                ? Colors.transparent 
                : (isDark ? Colors.white.withOpacity(0.03) : AppTheme.primaryContainer.withOpacity(0.04)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isRead 
                  ? (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))
                  : AppTheme.primary.withOpacity(0.15),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    note['title'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                if (!isRead)
                  Container(
                    margin: const EdgeInsets.only(top: 4, left: 8),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(
                  note['body'] ?? note['message'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
            onTap: () {
              if (!isRead) {
                _markRead(note['id'], index);
              }
            },
          ),
        );
      },
    );
  }
}
