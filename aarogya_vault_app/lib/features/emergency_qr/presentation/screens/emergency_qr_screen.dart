import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/security_helper.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../reminders/presentation/providers/reminders_provider.dart';
import 'emergency_access_screen.dart';
import '../../../../core/providers/api_provider.dart';

final qrFetchProvider = FutureProvider.autoDispose<String>((ref) async {
  try {
    final client = ref.read(apiClientProvider);
    final response = await client.get('/qr');
    // ApiClient interceptor automatically extracts 'data' from envelope
    if (response.data is Map) {
      final qrUrl = response.data['qr_url'];
      if (qrUrl != null) {
        return qrUrl as String;
      }
    }
    throw Exception("Invalid QR response");
  } catch (e) {
    rethrow;
  }
});

class EmergencyQRScreen extends ConsumerWidget {
  const EmergencyQRScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);
    final remindersState = ref.watch(remindersProvider);
    final profile = state.profile;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (profile == null) {
      return Scaffold(
        backgroundColor: isDark ? AppTheme.darkBg : AppTheme.surface,
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    // Extract dynamic medical history and active medications
    final allergies = state.history
        .where((e) => e.type.toLowerCase() == 'allergy')
        .map((e) => e.title)
        .toList();
    final chronicDiseases = state.history
        .where((e) => e.type.toLowerCase() == 'condition')
        .map((e) => e.title)
        .toList();
    final currentMedicines = remindersState.reminders
        .where((r) => r.isActive)
        .map((r) => '${r.medicineName} ${r.dosage}')
        .toList();

    // Generate emergency payload
    final payloadMap = {
      "user_id": profile.userId,
      "name": profile.fullName,
      "dob": profile.dob,
      "blood_group": profile.bloodGroup,
      "allergies": allergies.isNotEmpty ? allergies : ["None"],
      "chronic_diseases": chronicDiseases.isNotEmpty ? chronicDiseases : ["None"],
      "current_medicines": currentMedicines.isNotEmpty ? currentMedicines : ["None"],
      "emergency_contact": "${profile.emergencyContactName} (${profile.emergencyContactPhone})",
      "aadhaar_linked": profile.aadhaarNumber.isNotEmpty && !profile.aadhaarNumber.contains("Not Linked"),
    };
    final payloadJson = jsonEncode(payloadMap);
    final encryptedPayload = SecurityHelper.encrypt(payloadJson);

    // Watch online QR url fetch state
    final qrFuture = ref.watch(qrFetchProvider);
    String qrData = qrFuture.maybeWhen(
      data: (url) => url,
      orElse: () => encryptedPayload,
    );
    if (qrData.contains('127.0.0.1') || qrData.contains('localhost')) {
      qrData = qrData
          .replaceAll('http://127.0.0.1:8000', 'https://aarogya-vault.onrender.com')
          .replaceAll('http://localhost:8000', 'https://aarogya-vault.onrender.com');
    }
    final isOnlineQR = qrFuture.hasValue;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.surface,
      appBar: AppBar(
        title: Text(
          "Emergency QR Medical ID",
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isOnlineQR ? "Secure Emergency QR Link" : "Offline Emergency QR",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primary),
            ),
            const SizedBox(height: 8),
            Text(
              isOnlineQR
                  ? "Show this QR to emergency personnel to grant authorized read-only access to your minimal secure emergency profile online."
                  : "Show this QR to emergency personnel or police to grant authorized read-only access to vital medical parameters offline.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppTheme.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),

            // Card enclosing the QR Code (matching Stitch aesthetics)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark ? Colors.white10 : AppTheme.outlineVariant.withOpacity(0.5),
                  ),
                  boxShadow: AppTheme.premiumShadow,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 200.0,
                      gapless: false,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: AppTheme.primary,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.circle,
                        color: AppTheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      profile.fullName.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "DOB: ${profile.dob}",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Scan simulation buttons placed horizontally & polished
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EmergencyAccessScreen(
                            encryptedPayload: encryptedPayload,
                            accessType: EmergencyAccessType.medical,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.medical_services_rounded, size: 16),
                    label: Text("Medical Scan View", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EmergencyAccessScreen(
                            encryptedPayload: encryptedPayload,
                            accessType: EmergencyAccessType.police,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.local_police_rounded, size: 16),
                    label: Text("Police Scan View", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Critical Vitals Card matching Stitch design
            Container(
              padding: const EdgeInsets.all(20),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.tertiary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.emergency_rounded, color: AppTheme.tertiary, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "CRITICAL VITALS",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Blood Group",
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceVariant),
                      ),
                      Text(
                        profile.bloodGroup,
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.tertiary),
                      ),
                    ],
                  ),
                  const Divider(height: 24, thickness: 0.8),
                  Text(
                    "Known Allergies",
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: allergies.map((allergy) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.errorContainer,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.onErrorContainer.withOpacity(0.15)),
                        ),
                        child: Text(
                          allergy,
                          style: GoogleFonts.inter(
                            color: AppTheme.onErrorContainer,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Emergency Contact Card matching Stitch design
            Container(
              padding: const EdgeInsets.all(20),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.contact_phone_rounded, color: AppTheme.secondary, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "EMERGENCY CONTACT",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppTheme.primary.withOpacity(0.1),
                        child: Text(
                          profile.emergencyContactName.trim().isNotEmpty
                              ? profile.emergencyContactName.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).map((e) => e[0]).take(2).join('').toUpperCase()
                              : 'EC',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.emergencyContactName,
                              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              "Relation: Father",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final url = Uri.parse("tel:${profile.emergencyContactPhone}");
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      }
                    },
                    icon: const Icon(Icons.call_rounded, size: 18),
                    label: Text(
                      profile.emergencyContactPhone,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Security Disclaimer matching Stitch design
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white10 : AppTheme.outlineVariant.withOpacity(0.8),
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.verified_user_rounded, color: AppTheme.outline, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Keep this QR updated for better emergency support. Responders will gain limited, authorized access to your critical medical data only during emergencies.",
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: AppTheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (isOnlineQR) ...[
              OutlinedButton.icon(
                onPressed: () async {
                  try {
                    final client = ref.read(apiClientProvider);
                    final response = await client.post('/qr/regenerate');
                    if (response.statusCode == 200) {
                      ref.invalidate(qrFetchProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Secure QR token rotated successfully!")),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to rotate token: $e")),
                    );
                  }
                },
                icon: const Icon(Icons.sync_rounded),
                label: Text("Rotate Secure QR Token", style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Share Card button at the bottom
            ElevatedButton.icon(
              onPressed: () {
                Share.share(
                  "Aarogya Vault Secure Emergency Medical ID Card payload: $encryptedPayload",
                  subject: "Aarogya Vault Emergency Medical QR",
                );
              },
              icon: const Icon(Icons.share_outlined),
              label: Text("Share Emergency Card", style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
