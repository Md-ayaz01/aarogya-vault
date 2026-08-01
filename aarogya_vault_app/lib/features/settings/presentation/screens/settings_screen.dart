import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:math';
import 'dart:convert';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/api_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/database/local_db.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Consent toggles
  bool _allowAiProfile = true;
  bool _allowAiRecords = true;
  bool _allowEmergencyProfile = true;
  bool _allowEmergencyRecords = true;
  bool _consentLoading = false;

  // Doctor Access Consent state
  List<Map<String, dynamic>> _doctorsList = [];
  List<Map<String, dynamic>> _activeGrants = [];
  bool _grantingAccess = false;

  // Audit logs
  List<Map<String, dynamic>> _auditLogs = [];
  bool _auditLoading = true;

  // App preferences
  bool _darkMode = false;
  bool _biometrics = false;
  bool _notifications = true;

  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadConsent();
    _loadDoctorConsentData();
    _loadAuditLogs();
    _loadPreferences();
  }

  void _loadPreferences() {
    setState(() {
      _darkMode = LocalDB.get('pref_dark_mode', defaultValue: false) == true;
      _biometrics = LocalDB.get('biometric_token_key') != null;
      _notifications = LocalDB.get('pref_notifications', defaultValue: true) == true;
    });
  }

  Future<void> _toggleBiometrics(bool enable) async {
    if (enable) {
      try {
        final isSupported = await _localAuth.isDeviceSupported();
        final canCheckBio = await _localAuth.canCheckBiometrics;
        if (!isSupported || !canCheckBio) {
          _showSnackBar("Biometrics are not configured or supported on this device.");
          return;
        }

        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Authenticate to enable biometric secure access',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );

        if (authenticated) {
          final random = Random.secure();
          final values = List<int>.generate(32, (i) => random.nextInt(256));
          final secureToken = base64Url.encode(values);
          final success = await ref.read(authProvider.notifier).enrollBiometrics(secureToken);
          if (success) {
            setState(() {
              _biometrics = true;
            });
            _showSnackBar("Biometrics successfully enabled.");
          } else {
            final err = ref.read(authProvider).errorMessage;
            _showSnackBar(err ?? "Failed to register biometrics with server.");
          }
        }
      } catch (e) {
        _showSnackBar("Biometric setup error: $e");
      }
    } else {
      await LocalDB.save('biometric_token_key', null);
      setState(() {
        _biometrics = false;
      });
      _showSnackBar("Biometrics disabled.");
    }
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? const Color(0xFF1A2E45) : Colors.white,
          title: Text(
            'Change Password',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: Icon(Icons.lock_open_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: Icon(Icons.lock_rounded),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final old = oldPasswordController.text.trim();
                final newPass = newPasswordController.text.trim();
                final confirm = confirmPasswordController.text.trim();

                if (old.isEmpty || newPass.isEmpty || confirm.isEmpty) {
                  _showSnackBar('Please fill in all fields.');
                  return;
                }
                if (newPass.length < 6) {
                  _showSnackBar('New password must be at least 6 characters.');
                  return;
                }
                if (newPass != confirm) {
                  _showSnackBar('Confirm password does not match.');
                  return;
                }

                // Success simulation
                Navigator.pop(context);
                _showSnackBar('Password changed successfully.');
              },
              child: const Text('Change Password'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadConsent() async {
    try {
      final client = ref.read(apiClientProvider);
      final resp = await client.get('/consent');
      if (resp.statusCode == 200 && mounted) {
        setState(() {
          _allowAiProfile = resp.data['allow_ai_profile_read'] ?? true;
          _allowAiRecords = resp.data['allow_ai_records_read'] ?? true;
          _allowEmergencyProfile = resp.data['allow_emergency_profile_read'] ?? true;
          _allowEmergencyRecords = resp.data['allow_emergency_records_read'] ?? true;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveConsent() async {
    setState(() => _consentLoading = true);
    try {
      final client = ref.read(apiClientProvider);
      await client.put('/consent', data: {
        'allow_ai_profile_read': _allowAiProfile,
        'allow_ai_records_read': _allowAiRecords,
        'allow_emergency_profile_read': _allowEmergencyProfile,
        'allow_emergency_records_read': _allowEmergencyRecords,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Privacy settings saved.', style: GoogleFonts.inter()),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _consentLoading = false);
    }
  }

  Future<void> _loadDoctorConsentData() async {
    final client = ref.read(apiClientProvider);
    try {
      final docResp = await client.get('/consent/doctors-list');
      dynamic dData = docResp.data;
      if (dData is Map && dData.containsKey('data')) dData = dData['data'];
      if (dData is List && mounted) {
        setState(() {
          _doctorsList = List<Map<String, dynamic>>.from(dData);
        });
      }
    } catch (e) {
      debugPrint("Error loading doctors list: $e");
    }

    try {
      final grantsResp = await client.get('/consent/active-grants');
      dynamic gData = grantsResp.data;
      if (gData is Map && gData.containsKey('data')) gData = gData['data'];
      if (gData is List && mounted) {
        setState(() {
          _activeGrants = List<Map<String, dynamic>>.from(gData);
        });
      }
    } catch (e) {
      debugPrint("Error loading active grants: $e");
    }
  }

  Future<void> _grantDoctorConsent(int docId) async {
    setState(() => _grantingAccess = true);
    try {
      final client = ref.read(apiClientProvider);
      await client.post('/consent/grant-doctor-access', data: {
        'doctor_id': docId,
        'expires_in_hours': 24
      });
      await _loadDoctorConsentData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Doctor access consent granted for 24 hours.', style: GoogleFonts.inter()),
            backgroundColor: Colors.teal.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to grant doctor access consent.', style: GoogleFonts.inter()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _grantingAccess = false);
    }
  }

  Future<void> _revokeDoctorConsent(int docId) async {
    try {
      final client = ref.read(apiClientProvider);
      await client.post('/consent/revoke-doctor-access', queryParameters: {
        'doctor_id': docId
      });
      await _loadDoctorConsentData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Doctor access consent revoked.', style: GoogleFonts.inter()),
            backgroundColor: Colors.orange.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _loadAuditLogs() async {
    setState(() => _auditLoading = true);
    try {
      final client = ref.read(apiClientProvider);
      final resp = await client.get('/consent/audit-logs');
      if (resp.data is List && mounted) {
        setState(() {
          _auditLogs = List<Map<String, dynamic>>.from(resp.data);
          _auditLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _auditLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Settings',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, color: AppTheme.primary)),
        backgroundColor: isDark ? const Color(0xFF0B1C30) : AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            indicatorColor: AppTheme.primary,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
            unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
            tabs: const [
              Tab(text: 'General'),
              Tab(text: 'Privacy & Consent'),
              Tab(text: 'Audit Logs'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneralTab(isDark, colorScheme),
          _buildConsentTab(isDark),
          _buildAuditLogsTab(isDark),
        ],
      ),
    );
  }

  // ── General Tab ───────────────────────────────────────────────────────────────
  Widget _buildGeneralTab(bool isDark, ColorScheme colorScheme) {
    final sections = [
      _SettingsSection(title: 'Appearance', items: [
        _SettingItem(
          icon: Icons.dark_mode_rounded,
          iconColor: const Color(0xFF7C3AED),
          iconBg: const Color(0xFFF5F3FF),
          title: 'Dark Mode',
          trailing: Switch.adaptive(
            value: _darkMode,
            activeColor: AppTheme.primary,
            onChanged: (v) {
              setState(() => _darkMode = v);
              ref.read(themeProvider.notifier).toggleTheme(v);
            },
          ),
        ),
      ]),
      _SettingsSection(title: 'Security', items: [
        _SettingItem(
          icon: Icons.fingerprint_rounded,
          iconColor: const Color(0xFF0D9488),
          iconBg: const Color(0xFFF0FDFA),
          title: 'Biometric Login',
          subtitle: 'Face ID / Fingerprint',
          trailing: Switch.adaptive(
            value: _biometrics,
            activeColor: AppTheme.primary,
            onChanged: (v) => _toggleBiometrics(v),
          ),
        ),
      ]),
      _SettingsSection(title: 'Notifications', items: [
        _SettingItem(
          icon: Icons.notifications_rounded,
          iconColor: const Color(0xFFD97706),
          iconBg: const Color(0xFFFFFBEB),
          title: 'Push Notifications',
          subtitle: 'Medicine & appointment alerts',
          trailing: Switch.adaptive(
            value: _notifications,
            activeColor: AppTheme.primary,
            onChanged: (v) {
              setState(() => _notifications = v);
              LocalDB.save('pref_notifications', v);
            },
          ),
        ),
      ]),
      _SettingsSection(title: 'Account', items: [
        _SettingItem(
          icon: Icons.person_outline_rounded,
          iconColor: AppTheme.primary,
          iconBg: AppTheme.primaryContainer.withOpacity(0.15),
          title: 'Edit Profile',
          trailing: const Icon(Icons.chevron_right, color: AppTheme.outline),
          onTap: () {
            Navigator.pushNamed(context, '/profile');
          },
        ),
        _SettingItem(
          icon: Icons.lock_outline_rounded,
          iconColor: const Color(0xFF2563EB),
          iconBg: const Color(0xFFEFF6FF),
          title: 'Change PIN / Password',
          trailing: const Icon(Icons.chevron_right, color: AppTheme.outline),
          onTap: () {
            _showChangePasswordDialog(context);
          },
        ),
        _SettingItem(
          icon: Icons.logout_rounded,
          iconColor: AppTheme.error,
          iconBg: AppTheme.errorContainer.withOpacity(0.4),
          title: 'Sign Out',
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Text('Sign Out?',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                content: Text('You will need to verify your identity again to log in.',
                    style: GoogleFonts.inter(fontSize: 14)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
                    onPressed: () {
                      Navigator.pop(context);
                      ref.read(authProvider.notifier).logout().then((_) {
                        Navigator.pushNamedAndRemoveUntil(context, '/splash', (route) => false);
                      });
                    },
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            );
          },
        ),
      ]),
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: sections.map((s) => _buildSection(s, isDark)).toList(),
    );
  }

  // ── Privacy & Consent Tab ─────────────────────────────────────────────────────
  Widget _buildConsentTab(bool isDark) {
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: () async {
        await _loadConsent();
        await _loadDoctorConsentData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'These settings control what data the AI assistant and emergency responders can read from your vault.',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppTheme.primary, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildConsentGroup(
            title: '🤖 AI Health Assistant',
            subtitle: 'Aarogya Vault AI Doctor access',
            items: [
              _ConsentItem(
                title: 'Read Profile Data',
                subtitle: 'Name, DOB, blood group, gender',
                value: _allowAiProfile,
                onChanged: (v) => setState(() => _allowAiProfile = v),
              ),
              _ConsentItem(
                title: 'Read Medical Records',
                subtitle: 'Lab reports, prescriptions, history',
                value: _allowAiRecords,
                onChanged: (v) => setState(() => _allowAiRecords = v),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildConsentGroup(
            title: '🚨 Emergency Access',
            subtitle: 'Emergency QR code scanned data',
            items: [
              _ConsentItem(
                title: 'Include Profile in QR',
                subtitle: 'Name, blood group, allergies',
                value: _allowEmergencyProfile,
                onChanged: (v) => setState(() => _allowEmergencyProfile = v),
              ),
              _ConsentItem(
                title: 'Include Medical Records in QR',
                subtitle: 'Medicines, chronic conditions',
                value: _allowEmergencyRecords,
                onChanged: (v) => setState(() => _allowEmergencyRecords = v),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDoctorConsentSection(isDark),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _consentLoading ? null : _saveConsent,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _consentLoading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white,
                      ),
                    )
                  : Text('Save Privacy Settings',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildDoctorConsentSection(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1A2E45) : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.neutralDark;
    final subtextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final innerBg = isDark ? const Color(0xFF112236) : Colors.grey.shade50;
    final borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: AppTheme.premiumShadow,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.teal.shade900.withOpacity(0.5) : Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.medical_services_rounded, color: isDark ? Colors.teal.shade300 : Colors.teal, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Doctor Access Consent',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    Text(
                      'Grant verified doctors access to view your medical vault',
                      style: GoogleFonts.inter(fontSize: 12, color: subtextColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Active Grants List
          if (_activeGrants.isNotEmpty) ...[
            Text(
              'ACTIVE CONSENT GRANTS',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: isDark ? Colors.teal.shade300 : Colors.teal.shade800,
              ),
            ),
            const SizedBox(height: 8),
            ..._activeGrants.map((grant) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.teal.shade900.withOpacity(0.3) : Colors.teal.shade50.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.teal.shade700 : Colors.teal.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_user_rounded, color: isDark ? Colors.teal.shade300 : Colors.teal, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          grant['doctor_name'] ?? 'Doctor',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                        ),
                        Text(
                          '${grant['specialty']} | Granted: ${grant['granted_at']}',
                          style: GoogleFonts.inter(fontSize: 11, color: subtextColor),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _revokeDoctorConsent(grant['doctor_id']),
                    style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                    child: const Text('Revoke'),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 12),
          ],

          // Grant Access Dropdown & Action
          Text(
            'SELECT DOCTOR TO GRANT ACCESS (24 HOURS)',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: subtextColor,
            ),
          ),
          const SizedBox(height: 8),
          _doctorsList.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: innerBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: subtextColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No verified doctors available right now.',
                          style: GoogleFonts.inter(fontSize: 12, color: subtextColor),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _loadDoctorConsentData,
                        icon: const Icon(Icons.refresh_rounded, size: 14),
                        label: const Text('Refresh', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _doctorsList.length,
                  itemBuilder: (context, index) {
                    final doc = _doctorsList[index];
                    final docId = doc['doctor_id'] as int;
                    final isAlreadyGranted = _activeGrants.any((g) => g['doctor_id'] == docId);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: innerBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: isDark ? Colors.teal.shade900 : Colors.teal.shade100,
                            radius: 18,
                            child: Icon(Icons.person, color: isDark ? Colors.teal.shade200 : Colors.teal, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doc['full_name'] ?? 'Doctor Name',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                                ),
                                Text(
                                  '${doc['specialty']} • ${doc['hospital_name']}',
                                  style: GoogleFonts.inter(fontSize: 11, color: subtextColor),
                                ),
                              ],
                            ),
                          ),
                          isAlreadyGranted
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.teal.shade900 : Colors.teal.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Access Granted',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.teal.shade200 : Colors.teal.shade800,
                                    ),
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: _grantingAccess ? null : () => _grantDoctorConsent(docId),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('Grant Access', style: TextStyle(fontSize: 12)),
                                ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildConsentGroup({
    required String title,
    required String subtitle,
    required List<_ConsentItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 2),
        Text(subtitle,
            style: GoogleFonts.inter(
                fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.white
                : const Color(0xFF1A2E45),
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.premiumShadow,
          ),
          child: Column(
            children: items
                .map((item) => _buildConsentTile(item))
                .expand((w) => [w, Divider(height: 1, color: AppTheme.outlineVariant.withOpacity(0.3))])
                .take(items.length * 2 - 1)
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildConsentTile(_ConsentItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 2),
                Text(item.subtitle,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Switch.adaptive(
            value: item.value,
            activeColor: AppTheme.primary,
            onChanged: item.onChanged,
          ),
        ],
      ),
    );
  }

  // ── Audit Logs Tab ─────────────────────────────────────────────────────────────
  Widget _buildAuditLogsTab(bool isDark) {
    if (_auditLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (_auditLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded,
                size: 64, color: AppTheme.primary.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('No activity recorded yet',
                style: GoogleFonts.inter(
                    fontSize: 17, fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _loadAuditLogs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _auditLogs.length,
        itemBuilder: (_, i) {
          final log = _auditLogs[i];
          final action = log['action'] as String? ?? '';
          final ts = log['timestamp'] as String? ?? '';
          final details = log['details'] as String? ?? '';

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A2E45) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppTheme.premiumShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: _auditColor(action).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_auditIcon(action),
                      size: 20, color: _auditColor(action)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(action.replaceAll('_', ' '),
                          style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface)),
                      if (details.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(details,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ),
                    ],
                  ),
                ),
                Text(
                  _formatLogTime(ts),
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────
  Widget _buildSection(_SettingsSection section, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10, top: 12),
          child: Text(section.title,
              style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A2E45) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.premiumShadow,
          ),
          child: Column(
            children: section.items
                .asMap()
                .entries
                .map((e) {
                  final isLast = e.key == section.items.length - 1;
                  return _buildSettingTile(e.value, isLast);
                })
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile(_SettingItem item, bool isLast) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: item.iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, size: 20, color: item.iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: item.icon == Icons.logout_rounded
                              ? AppTheme.error
                              : Theme.of(context).colorScheme.onSurface)),
                  if (item.subtitle != null)
                    Text(item.subtitle!,
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            if (item.trailing != null) item.trailing!,
          ],
        ),
      ),
    );
  }

  Color _auditColor(String action) {
    if (action.contains('LOGIN')) return AppTheme.secondary;
    if (action.contains('UPLOAD')) return const Color(0xFF7C3AED);
    if (action.contains('EMERGENCY')) return AppTheme.error;
    if (action.contains('AI')) return const Color(0xFF0D9488);
    if (action.contains('CONSENT')) return AppTheme.primary;
    return AppTheme.outline;
  }

  IconData _auditIcon(String action) {
    if (action.contains('LOGIN')) return Icons.login_rounded;
    if (action.contains('REGISTER')) return Icons.how_to_reg_rounded;
    if (action.contains('UPLOAD')) return Icons.upload_file_rounded;
    if (action.contains('EMERGENCY')) return Icons.emergency_rounded;
    if (action.contains('AI')) return Icons.smart_toy_rounded;
    if (action.contains('CONSENT')) return Icons.privacy_tip_rounded;
    return Icons.history_rounded;
  }

  String _formatLogTime(String ts) {
    final dt = DateTime.tryParse(ts);
    if (dt == null) return '';
    final date = '${dt.day}/${dt.month}/${dt.year}';
    final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$date\n$time';
  }
}

// ── Data Models ───────────────────────────────────────────────────────────────
class _SettingsSection {
  final String title;
  final List<_SettingItem> items;
  const _SettingsSection({required this.title, required this.items});
}

class _SettingItem {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _SettingItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });
}

class _ConsentItem {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ConsentItem({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
}
