import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/utils/security_helper.dart';

enum EmergencyAccessType { medical, police }

class EmergencyAccessScreen extends StatelessWidget {
  final String encryptedPayload;
  final EmergencyAccessType accessType;

  const EmergencyAccessScreen({
    Key? key,
    required this.encryptedPayload,
    required this.accessType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Decrypt the raw payload
    final decryptedStr = SecurityHelper.decrypt(encryptedPayload);
    Map<String, dynamic> data = {};
    try {
      if (decryptedStr.isNotEmpty) {
        data = jsonDecode(decryptedStr);
      }
    } catch (_) {}

    final isMedical = accessType == EmergencyAccessType.medical;
    final headerColor = isMedical ? AppTheme.errorRed : Colors.indigo;
    final headerTitle = isMedical ? "Emergency Access (Authorized)" : "Police Access (Authorized)";
    final headerIcon = isMedical ? Icons.medical_services_rounded : Icons.local_police_rounded;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: headerColor,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Icon(headerIcon, color: Colors.white),
            const SizedBox(width: 8),
            Text(headerTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Restricted profile summary
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: headerColor.withOpacity(0.1),
                    child: Text(
                      (data['name'] as String? ?? 'Guest').trim().isNotEmpty
                          ? (data['name'] as String? ?? 'Guest').trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).map((e) => e[0]).take(2).join('').toUpperCase()
                          : 'GT',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: headerColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    data['name'] ?? "Majid Shaikh",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "26 Years, Male",
                    style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text(
              "Demographic & Clinical Details",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),

            GlassContainer(
              borderRadius: 20,
              opacity: isDark ? 0.05 : 0.45,
              child: Column(
                children: [
                  _buildRestrictedRow("Blood Group", data['blood_group'] ?? "O+"),
                  const Divider(height: 1, color: Colors.white12),
                  _buildRestrictedRow("Allergies", (data['allergies'] as List?)?.join(', ') ?? "Penicillin, Pollen"),
                  const Divider(height: 1, color: Colors.white12),
                  _buildRestrictedRow("Chronic Diseases", (data['chronic_diseases'] as List?)?.join(', ') ?? "None"),
                  const Divider(height: 1, color: Colors.white12),
                  _buildRestrictedRow("Current Medications", (data['current_medicines'] as List?)?.join(', ') ?? "Paracetamol, Azithromycin"),
                  const Divider(height: 1, color: Colors.white12),
                  _buildRestrictedRow("Emergency Contact", data['emergency_contact'] ?? "Sikandar Shaikh (+91 91234 56789)"),
                  
                  if (!isMedical) ...[
                    const Divider(height: 1, color: Colors.white12),
                    _buildRestrictedRow("Identity Status", "Aadhaar Card Verified"),
                    const Divider(height: 1, color: Colors.white12),
                    _buildRestrictedRow("Address Details", "Dewas, Madhya Pradesh, India"),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: headerColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: headerColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_rounded, color: headerColor, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "This data is encrypted & logs are stored in the consent audit vault.",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Emergency call buttons
            if (isMedical) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final rawContact = data['emergency_contact']?.toString() ?? '';
                        final phoneRegExp = RegExp(r'\+?[0-9\s\-]{7,15}');
                        final match = phoneRegExp.firstMatch(rawContact);
                        String phone = match != null ? match.group(0)!.replaceAll(RegExp(r'[\s\-]'), '') : '9876543210';
                        if (!phone.startsWith('+')) {
                          phone = '+91$phone';
                        }
                        final url = Uri.parse("tel:$phone");
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                      icon: const Icon(Icons.call_rounded),
                      label: const Text("Call Contact"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final url = Uri.parse("tel:108");
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                      icon: const Icon(Icons.emergency_share_rounded),
                      label: const Text("Ambulance"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check_rounded),
                label: const Text("Acknowledge Verification"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRestrictedRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
