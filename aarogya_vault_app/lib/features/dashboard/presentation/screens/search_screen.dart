import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../reports/presentation/providers/reports_provider.dart';
import '../providers/dashboard_provider.dart';
import '../../../prescriptions/presentation/providers/prescriptions_provider.dart';
import '../../../reminders/presentation/providers/reminders_provider.dart';
import '../../../prescriptions/presentation/screens/prescription_details_screen.dart';
import '../../../medical_history/presentation/screens/medical_history_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportsState = ref.watch(reportsProvider);
    final dashboardState = ref.watch(dashboardProvider);
    final prescriptionsState = ref.watch(prescriptionsProvider);
    final remindersState = ref.watch(remindersProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter results
    final queryLower = _query.toLowerCase().trim();
    final matchingReports = queryLower.isEmpty
        ? []
        : reportsState.reports
            .where((r) => r.title.toLowerCase().contains(queryLower) || r.type.toLowerCase().contains(queryLower))
            .toList();

    final matchingHistory = queryLower.isEmpty
        ? []
        : dashboardState.history
            .where((h) => h.title.toLowerCase().contains(queryLower) || h.description.toLowerCase().contains(queryLower))
            .toList();

    final matchingPrescriptions = queryLower.isEmpty
        ? []
        : prescriptionsState.prescriptions
            .where((p) => p.doctorName.toLowerCase().contains(queryLower) || p.diagnosis.toLowerCase().contains(queryLower))
            .toList();

    final matchingReminders = queryLower.isEmpty
        ? []
        : remindersState.reminders
            .where((r) => r.medicineName.toLowerCase().contains(queryLower) || r.instruction.toLowerCase().contains(queryLower))
            .toList();

    final totalResults = matchingReports.length + matchingHistory.length + matchingPrescriptions.length + matchingReminders.length;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.surface,
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Padding(
          padding: const EdgeInsets.only(right: 20.0),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A2E45) : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: GoogleFonts.inter(fontSize: 14),
              onChanged: (val) {
                setState(() {
                  _query = val;
                });
              },
              decoration: InputDecoration(
                hintText: "Search reports, history, pills...",
                hintStyle: GoogleFonts.inter(color: isDark ? Colors.white60 : Colors.black38, fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.primary),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _query = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
      ),
      body: _query.isEmpty
          ? _buildEmptyState("Search medical records", "Type a report name, doctor name, medicine, or allergy diagnosis to quickly find it in your secure vault.")
          : totalResults == 0
              ? _buildEmptyState("No matching records found", "Verify your keywords or check if the record is uploaded to your Aarogya Vault profile.")
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      "$totalResults results found for '$_query'",
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.outline),
                    ),
                    const SizedBox(height: 20),

                    // Matching Reports
                    if (matchingReports.isNotEmpty) ...[
                      _buildHeader("REPORTS (${matchingReports.length})"),
                      ...matchingReports.map((report) => _buildResultTile(
                            icon: Icons.description_rounded,
                            title: report.title,
                            subtitle: "Date: ${report.date} • Type: ${report.type}",
                            color: const Color(0xFF7C3AED),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, '/reports');
                            },
                          )),
                      const SizedBox(height: 24),
                    ],

                    // Matching Prescriptions
                    if (matchingPrescriptions.isNotEmpty) ...[
                      _buildHeader("PRESCRIPTIONS (${matchingPrescriptions.length})"),
                      ...matchingPrescriptions.map((pres) => _buildResultTile(
                            icon: Icons.receipt_long_rounded,
                            title: pres.doctorName,
                            subtitle: "Diagnosis: ${pres.diagnosis} • Date: ${pres.date}",
                            color: AppTheme.primaryTeal,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PrescriptionDetailsScreen(prescription: pres),
                                ),
                              );
                            },
                          )),
                      const SizedBox(height: 24),
                    ],

                    // Matching History
                    if (matchingHistory.isNotEmpty) ...[
                      _buildHeader("MEDICAL HISTORY (${matchingHistory.length})"),
                      ...matchingHistory.map((hist) => _buildResultTile(
                            icon: Icons.history_edu_rounded,
                            title: hist.title,
                            subtitle: "Details: ${hist.description} • Category: ${hist.type.toUpperCase()}",
                            color: const Color(0xFF16A34A),
                            onTap: () {
                              Navigator.pop(context);
                              // Map the categories to initial tab indexes: condition=1, allergy=2, surgery=3, family=4, vaccination=5
                              int tabIndex = 0;
                              if (hist.type.toLowerCase() == 'condition') tabIndex = 1;
                              if (hist.type.toLowerCase() == 'allergy') tabIndex = 2;
                              if (hist.type.toLowerCase() == 'surgery') tabIndex = 3;
                              if (hist.type.toLowerCase() == 'family') tabIndex = 4;
                              if (hist.type.toLowerCase() == 'vaccination') tabIndex = 5;

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MedicalHistoryScreen(initialTabIndex: tabIndex),
                                ),
                              );
                            },
                          )),
                      const SizedBox(height: 24),
                    ],

                    // Matching Reminders
                    if (matchingReminders.isNotEmpty) ...[
                      _buildHeader("MEDICINE REMINDERS (${matchingReminders.length})"),
                      ...matchingReminders.map((rem) => _buildResultTile(
                            icon: Icons.medication_rounded,
                            title: rem.medicineName,
                            subtitle: "Dose: ${rem.dosage} • Time: ${rem.time} • Instruction: ${rem.instruction}",
                            color: const Color(0xFFE11D48),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, '/reminders');
                            },
                          )),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: AppTheme.primary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildResultTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : AppTheme.outlineVariant.withOpacity(0.5),
        ),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14.5),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.w500),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.outline,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.saved_search_rounded, size: 54, color: AppTheme.primary),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
