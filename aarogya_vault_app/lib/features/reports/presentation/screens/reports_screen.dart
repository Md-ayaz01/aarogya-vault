import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../../core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/reports_provider.dart';


class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsState = ref.watch(reportsProvider);
    final reports = reportsState.reports;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.darkBg : AppTheme.surface,
        appBar: AppBar(
          title: Text(
            "Medical Reports",
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 20),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white10 : AppTheme.outlineVariant.withOpacity(0.5),
                    width: 1,
                  ),
                ),
              ),
              child: TabBar(
                indicatorColor: AppTheme.primary,
                labelColor: AppTheme.primary,
                unselectedLabelColor: isDark ? Colors.white60 : AppTheme.onSurfaceVariant,
                indicatorWeight: 3,
                labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
                tabs: const [
                  Tab(text: "All"),
                  Tab(text: "Lab"),
                  Tab(text: "Imaging"),
                  Tab(text: "Others"),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildReportList(context, ref, reports, null),
            _buildReportList(context, ref, reports, "Lab"),
            _buildReportList(context, ref, reports, "Imaging"),
            _buildReportList(context, ref, reports, "Others"),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            debugPrint('FAB pressed');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Opening upload sheet...')),
            );
            debugPrint('Calling upload sheet');
            _showUploadSheet(context, ref);
            debugPrint('Upload sheet call returned');
          },
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.upload_file_rounded, size: 28),
        ), // end FAB
      ), // close Scaffold
    ); // close DefaultTabController
  }

  IconData _getReportIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('x-ray') || t.contains('xray') || t.contains('radiology')) return Icons.biotech_rounded;
    if (t.contains('mri') || t.contains('brain') || t.contains('ct') || t.contains('scan')) return Icons.psychology_rounded;
    if (t.contains('ecg') || t.contains('ekg') || t.contains('heart') || t.contains('cardio')) return Icons.favorite_rounded;
    return Icons.description_rounded;
  }

  Widget _buildReportList(BuildContext context, WidgetRef ref, List<dynamic> reports, String? filterType) {
    final filtered = filterType == null
        ? reports
        : reports.where((r) => r.type.toLowerCase() == filterType.toLowerCase()).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_off_rounded, size: 64, color: AppTheme.outlineVariant.withOpacity(0.6)),
            const SizedBox(height: 16),
            Text(
              "No reports uploaded",
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.outline),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...filtered.map((report) {
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
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: () => _showReportOptions(context, ref, report),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _getReportIcon(report.title),
                            color: AppTheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                report.title,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: isDark ? Colors.white : AppTheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                report.date,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppTheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "PDF",
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.more_vert_rounded, color: AppTheme.onSurfaceVariant, size: 20),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 16),
          // Informational Banner matching Stitch design
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
                const Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Keep your records updated",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: isDark ? Colors.white : AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Upload recent reports to help our AI Assistant provide more accurate health insights.",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReportOptions(BuildContext context, WidgetRef ref, dynamic report) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  report.title,
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  "Uploaded: ${report.date}",
                  style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showAIExplanation(context, ref, report);
                  },
                  icon: const Icon(Icons.psychology_outlined),
                  label: Text("Explain Report with AI", style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    if (report.fileUrl.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Opening ${report.title} for download..."),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      final uri = Uri.parse(report.fileUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Could not open download link."),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("No download link available for this report."),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.download_rounded),
                  label: Text("Download Report PDF", style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppTheme.primary)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Secure temporary sharing link copied to clipboard!"),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.share_outlined),
                  label: Text("Share Report (Secure Link)", style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppTheme.primary)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _confirmDeleteReport(context, ref, report.id, report.title);
                  },
                  icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
                  label: Text("Delete Report", style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppTheme.error)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteReport(BuildContext context, WidgetRef ref, int reportId, String title) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete Report?", style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
          content: Text("Are you sure you want to permanently delete '$title'?", style: GoogleFonts.inter()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.outline)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await ref.read(reportsProvider.notifier).deleteReport(reportId);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Report deleted successfully."),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Text("Delete", style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppTheme.error)),
            ),
          ],
        );
      },
    );
  }

  void _showAIExplanation(BuildContext context, WidgetRef ref, dynamic report) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.psychology_outlined, color: AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(child: Text("AI Explanation", style: GoogleFonts.inter(fontWeight: FontWeight.w800))),
            ],
          ),
          content: FutureBuilder<String>(
            future: ref.read(reportsProvider.notifier).getReportExplanation(report.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 100,
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Text("Error: ${snapshot.error}", style: GoogleFonts.inter());
              }
              return SingleChildScrollView(
                child: Text(
                  snapshot.data ?? "",
                  style: GoogleFonts.inter(height: 1.4, fontSize: 14),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close", style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppTheme.primary)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showUploadSheet(BuildContext context, WidgetRef ref) async {
    debugPrint('Entering _showUploadSheet');
    try {
      final titleController = TextEditingController();
      String reportType = "Lab";
      final isDark = Theme.of(context).brightness == Brightness.dark;

      debugPrint('Calling showModalBottomSheet');
      await showModalBottomSheet(
        context: context,
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        isScrollControlled: true,
        useRootNavigator: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text("Upload Health Report", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: "Report Title (e.g. Lipid Profile)",
                        labelStyle: GoogleFonts.inter(fontSize: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text("Category:  ", style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                        DropdownButton<String>(
                          value: reportType,
                          items: const [
                            DropdownMenuItem(value: "Lab", child: Text("Lab Report")),
                            DropdownMenuItem(value: "Imaging", child: Text("Imaging (X-Ray, MRI)")),
                            DropdownMenuItem(value: "Others", child: Text("Others")),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() {
                                reportType = val;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    

ElevatedButton(
  onPressed: () async {
    debugPrint('Upload button pressed');

    // Validate title
    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    try {
      // Use standard FilePicker for both Web and Mobile
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      debugPrint('FilePicker result: $result');
      if (result == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File picker cancelled')),
          );
        }
        return;
      }

      final file = result.files.single;

      // Web safety checks
      if (kIsWeb && (file.bytes == null || file.name.isEmpty)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid file selected on web')),
          );
        }
        return;
      }

      // Non‑web safety checks
      if (!kIsWeb && file.path == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File path null (non‑web)')),
          );
        }
        return;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selected file: ${file.name}')),
        );
      }

      // Perform real upload logic
      if (kIsWeb) {
        await ref.read(reportsProvider.notifier).uploadReport(
          title: titleController.text.trim(),
          date: DateTime.now().toIso8601String().split('T').first,
          type: reportType,
          bytes: file.bytes,
          fileName: file.name,
        );
      } else {
        await ref.read(reportsProvider.notifier).uploadReport(
          title: titleController.text.trim(),
          date: DateTime.now().toIso8601String().split('T').first,
          type: reportType,
          filePath: file.path,
          fileName: file.name,
        );
      }

      if (context.mounted) Navigator.pop(context);
    } catch (e, stack) {
      debugPrint('Error during file picking/upload: $e');
      debugPrint(stack.toString());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  },
  child: Text('Upload', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
),
                  ],
                ),
              );
            },
          );
        },
      );
      debugPrint('_showUploadSheet completed');
    } catch (e, stack) {
      debugPrint('Error in _showUploadSheet: $e');
      debugPrint(stack.toString());
    }
  }
}
