import 'package:flutter/material.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/network/api_client.dart';

/// Doctor's own professional profile screen.
/// Matches Stitch design: stitch_designs/doctor/profile.html
class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final apiClient = getIt<ApiClient>();
      final response = await apiClient.get('/doctor/profile');
      setState(() { _profileData = response.data as Map<String, dynamic>?; });
    } catch (e) {
      setState(() { _errorMessage = 'Failed to load profile. Please retry.'; });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    if (_isLoading) {
      return Scaffold(appBar: AppBar(title: const Text('My Profile')), body: const Center(child: CircularProgressIndicator()));
    }
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.error_outline_rounded, size: 64, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text(_errorMessage!, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _fetchProfile, child: const Text('Retry')),
        ]))),
      );
    }
    final name = _profileData?['full_name'] ?? 'Dr.';
    final specialty = _profileData?['specialty'] ?? 'Specialist';
    final hospital = _profileData?['hospital_name'] ?? 'Hospital';
    final regNum = _profileData?['registration_number'] ?? 'N/A';
    final email = _profileData?['email'] ?? 'N/A';
    final phone = _profileData?['phone'] ?? 'N/A';
    final isVerified = _profileData?['is_verified'] == true;
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile'), actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _fetchProfile)]),
      body: RefreshIndicator(
        onRefresh: _fetchProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Identity Card
            Container(
              width: double.infinity, padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [primary, primary.withAlpha(200)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: primary.withAlpha(50), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Stack(children: [
                  Container(width: 80, height: 80,
                    decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white, width: 2)),
                    child: const Icon(Icons.person_rounded, size: 44, color: Colors.white)),
                  if (isVerified) Positioned(bottom: -2, right: -2, child: Container(padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.verified_rounded, color: Color(0xFF006B53), size: 18))),
                ]),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(specialty, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Row(children: [const Icon(Icons.local_hospital_outlined, color: Colors.white54, size: 14), const SizedBox(width: 4),
                    Flexible(child: Text(hospital, style: const TextStyle(color: Colors.white54, fontSize: 13), overflow: TextOverflow.ellipsis))]),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, children: [
                    _badge('Senior Consultant'),
                    if (isVerified) _badge('Verified'),
                  ]),
                ])),
              ]),
            ),
            const SizedBox(height: 24),
            // Stats
            Row(children: [
              _stat(context, '12y', 'Experience', Icons.workspace_premium_rounded),
              const SizedBox(width: 12),
              _stat(context, '5k+', 'Patients', Icons.people_rounded),
              const SizedBox(width: 12),
              _stat(context, '4.9', 'Rating', Icons.star_rounded),
            ]),
            const SizedBox(height: 28),
            // Professional Details
            _sectionHeader(context, 'Professional Details', Icons.badge_rounded),
            const SizedBox(height: 12),
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
              _detailRow('Specialization', specialty),
              const Divider(),
              _detailRow('License / Reg. No.', regNum),
              const Divider(),
              _detailRow('Hospital Affiliation', hospital),
              const Divider(),
              _detailRow('Digital Signature', isVerified ? 'Active & Encrypted' : 'Pending Verification', valueColor: isVerified ? Colors.green : Colors.orange),
            ]))),
            const SizedBox(height: 24),
            // Account Settings
            _sectionHeader(context, 'Account Settings', Icons.manage_accounts_rounded),
            const SizedBox(height: 12),
            Card(child: Column(children: [
              _settingTile(Icons.person_rounded, 'Personal Information', email),
              const Divider(height: 1),
              _settingTile(Icons.phone_rounded, 'Contact Details', phone),
              const Divider(height: 1),
              _settingTile(Icons.domain_rounded, 'Hospital Affiliations', hospital),
              const Divider(height: 1),
              _settingTile(Icons.calendar_month_rounded, 'Work Schedule', 'Mon-Fri 9:00 AM - 5:00 PM'),
            ])),
            const SizedBox(height: 24),
            // Preferences
            _sectionHeader(context, 'App Preferences', Icons.tune_rounded),
            const SizedBox(height: 12),
            Card(child: Column(children: [
              _settingTile(Icons.notifications_rounded, 'Push Notifications', 'Appointment alerts, critical events'),
              const Divider(height: 1),
              _settingTile(Icons.dark_mode_rounded, 'Dark Mode', 'Switch to dark clinical theme'),
              const Divider(height: 1),
              _settingTile(Icons.translate_rounded, 'Language', 'English (India)'),
            ])),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }

  Widget _badge(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withAlpha(60))),
    child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)));

  Widget _stat(BuildContext context, String val, String label, IconData icon) {
    final p = Theme.of(context).colorScheme.primary;
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(color: p.withAlpha(15), borderRadius: BorderRadius.circular(16), border: Border.all(color: p.withAlpha(30))),
      child: Column(children: [
        Icon(icon, color: p, size: 22),
        const SizedBox(height: 8),
        Text(val, style: TextStyle(color: p, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ]),
    ));
  }

  Widget _sectionHeader(BuildContext context, String title, IconData icon) => Row(children: [
    Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
    const SizedBox(width: 8),
    Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
  ]);

  Widget _detailRow(String label, String value, {Color? valueColor}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey, fontSize: 14)),
      Flexible(child: Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: valueColor), textAlign: TextAlign.end)),
    ]),
  );

  Widget _settingTile(IconData icon, String title, String sub) => ListTile(
    leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
    subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
  );
}
