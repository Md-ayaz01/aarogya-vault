import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../../features/settings/presentation/screens/settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);
    final profile = dashboardState.profile;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (profile == null) {
      return Scaffold(
        backgroundColor: isDark ? AppTheme.darkBg : AppTheme.surface,
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.surface,
      appBar: AppBar(
        title: Text(
          "My Profile",
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.primary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardProvider.notifier).fetchDashboardData(),
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar and Name Card
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppTheme.primary.withOpacity(0.12),
                          child: Text(
                            profile.fullName.trim().isNotEmpty
                                ? profile.fullName.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).map((e) => e[0]).take(2).join('').toUpperCase()
                                : 'US',
                            style: GoogleFonts.inter(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      profile.fullName,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${profile.ageString}, ${profile.gender}",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Personal Details Card Group
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white10 : AppTheme.outlineVariant.withOpacity(0.5),
                  ),
                  boxShadow: AppTheme.premiumShadow,
                ),
                child: Column(
                  children: [
                    _buildProfileItem(
                      icon: Icons.bloodtype_outlined,
                      label: "Blood Group",
                      value: profile.bloodGroup,
                      context: context,
                    ),
                    _buildDivider(isDark),
                    _buildProfileItem(
                      icon: Icons.calendar_today_outlined,
                      label: "Date of Birth",
                      value: profile.dob,
                      context: context,
                    ),
                    _buildDivider(isDark),
                    _buildProfileItem(
                      icon: Icons.phone_outlined,
                      label: "Mobile Number",
                      value: profile.phone.isNotEmpty ? profile.phone : "Not Provided",
                      context: context,
                      trailing: const Icon(Icons.verified_rounded, color: AppTheme.secondary, size: 20),
                    ),
                    _buildDivider(isDark),
                    _buildProfileItem(
                      icon: Icons.location_on_outlined,
                      label: "Address",
                      value: profile.address,
                      context: context,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Emergency Details Card Group
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white10 : AppTheme.outlineVariant.withOpacity(0.5),
                  ),
                  boxShadow: AppTheme.premiumShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, top: 12.0, bottom: 8.0),
                      child: Text(
                        "EMERGENCY DETAILS",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    _buildProfileItem(
                      icon: Icons.emergency_outlined,
                      label: "Emergency Contact",
                      value: "${profile.emergencyContactName} (Father)",
                      subValue: profile.emergencyContactPhone,
                      iconColor: AppTheme.tertiary,
                      context: context,
                    ),
                    _buildDivider(isDark),
                    _buildProfileItem(
                      icon: Icons.fingerprint_outlined,
                      label: "Aadhaar Number",
                      value: "XXXX XXXX 1234",
                      context: context,
                      trailing: Icon(Icons.visibility_off_rounded, color: AppTheme.outline.withOpacity(0.6), size: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Edit Profile Button
              ElevatedButton.icon(
                onPressed: () => _showEditProfileSheet(context, ref, profile),
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: Text("Edit Profile", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 24),

              // Security Encrypted Watermark matching Stitch design
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline_rounded, color: AppTheme.outlineVariant, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    "HEALTH RECORD SECURED WITH 256-BIT ENCRYPTION",
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.outlineVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 0.8,
      color: isDark ? Colors.white10 : AppTheme.outlineVariant.withOpacity(0.4),
      indent: 56,
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String label,
    required String value,
    String? subValue,
    Color iconColor = AppTheme.primary,
    Widget? trailing,
    required BuildContext context,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.outline,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppTheme.onSurface,
                  ),
                ),
                if (subValue != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subValue,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.tertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context, WidgetRef ref, dynamic profile) {
    final nameController = TextEditingController(text: profile.fullName);
    final dobController = TextEditingController(text: profile.dob);
    final genderController = TextEditingController(text: profile.gender);
    final bloodController = TextEditingController(text: profile.bloodGroup);
    final addressController = TextEditingController(text: profile.address);
    final emergencyNameController = TextEditingController(text: profile.emergencyContactName);
    final emergencyPhoneController = TextEditingController(text: profile.emergencyContactPhone);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text("Edit Patient Profile", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Full Name"),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: dobController,
                        decoration: const InputDecoration(labelText: "Date of Birth"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: genderController,
                        decoration: const InputDecoration(labelText: "Gender"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bloodController,
                  decoration: const InputDecoration(labelText: "Blood Group"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: "Address"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emergencyNameController,
                  decoration: const InputDecoration(labelText: "Emergency Contact Name"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emergencyPhoneController,
                  decoration: const InputDecoration(labelText: "Emergency Contact Phone"),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    await ref.read(dashboardProvider.notifier).updateProfile(
                      fullName: nameController.text.trim(),
                      dob: dobController.text.trim(),
                      gender: genderController.text.trim(),
                      bloodGroup: bloodController.text.trim(),
                      address: addressController.text.trim(),
                      emergencyContactName: emergencyNameController.text.trim(),
                      emergencyContactPhone: emergencyPhoneController.text.trim(),
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Profile updated successfully."),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text("Save Changes", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
