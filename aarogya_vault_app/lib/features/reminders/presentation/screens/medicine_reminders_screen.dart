import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/appointment_model.dart';
import '../../../../core/models/reminder_model.dart';
import '../providers/reminders_provider.dart';

class MedicineRemindersScreen extends ConsumerWidget {
  const MedicineRemindersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(remindersProvider);
    final reminders = state.reminders;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.darkBg : AppTheme.surface,
        appBar: AppBar(
          title: Text(
            "Medicine Reminders",
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
                  Tab(text: "Today"),
                  Tab(text: "Upcoming"),
                  Tab(text: "Missed"),
                  Tab(text: "Appointments"),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildReminderList(
              context,
              ref,
              reminders.where((r) => r.status != 'Missed').toList(),
              showAdherence: true,
            ),
            _buildReminderList(
              context,
              ref,
              reminders.where((r) => r.status == 'Pending').toList(),
              showAdherence: false,
            ),
            _buildReminderList(
              context,
              ref,
              reminders.where((r) => r.status == 'Missed').toList(),
              showAdherence: false,
            ),
            _buildAppointmentList(context, ref, state.appointments),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (context) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    ListTile(
                      leading: const Icon(Icons.medication_rounded, color: AppTheme.primary),
                      title: Text("Schedule Medicine Reminder", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      onTap: () {
                        Navigator.pop(context);
                        _showAddMedicineDialog(context, ref);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.event_note_rounded, color: AppTheme.primary),
                      title: Text("Book Doctor Appointment", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      onTap: () {
                        Navigator.pop(context);
                        _showBookAppointmentDialog(context, ref);
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_rounded, size: 24),
          label: Text("Add / Book", style: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        ),
      ),
    );
  }

  int _getHour(String timeStr) {
    try {
      final parts = timeStr.trim().split(' ');
      if (parts.isEmpty) return 0;
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      if (parts.length > 1 && parts[1].toUpperCase() == 'PM' && hour < 12) {
        hour += 12;
      } else if (parts.length > 1 && parts[1].toUpperCase() == 'AM' && hour == 12) {
        hour = 0;
      }
      return hour;
    } catch (e) {
      return 0;
    }
  }

  Widget _buildReminderList(
    BuildContext context,
    WidgetRef ref,
    List<ReminderModel> list, {
    required bool showAdherence,
  }) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication_liquid_rounded, size: 64, color: AppTheme.outlineVariant.withOpacity(0.6)),
            const SizedBox(height: 16),
            Text(
              "No medicine reminders",
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.outline),
            ),
          ],
        ),
      );
    }

    final morningList = list.where((r) => r.time.toUpperCase().contains('AM')).toList();
    final afternoonList = list.where((r) => r.time.toUpperCase().contains('PM') && _getHour(r.time) < 17).toList();
    final nightList = list.where((r) => r.time.toUpperCase().contains('PM') && _getHour(r.time) >= 17).toList();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showAdherence) ...[
            _buildAdherenceCard(list, context),
            const SizedBox(height: 24),
          ],
          _buildReminderSection("Morning", Icons.schedule_rounded, morningList, context, ref),
          _buildReminderSection("Afternoon", Icons.wb_sunny_rounded, afternoonList, context, ref),
          _buildReminderSection("Night", Icons.dark_mode_rounded, nightList, context, ref),
        ],
      ),
    );
  }

  Widget _buildAdherenceCard(List<ReminderModel> list, BuildContext context) {
    final total = list.length;
    final taken = list.where((r) => r.status == 'Taken').length;
    final double percent = total > 0 ? taken / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withOpacity(0.12), width: 1),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Adherence Score",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "You've taken $taken/$total doses today. Keep it up!",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 8,
                  backgroundColor: AppTheme.outlineVariant.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              ),
            ],
          ),
          Positioned(
            right: -8,
            bottom: -8,
            child: Opacity(
              opacity: 0.08,
              child: Icon(Icons.health_and_safety_rounded, size: 72, color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderSection(
    String title,
    IconData icon,
    List<ReminderModel> items,
    BuildContext context,
    WidgetRef ref,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              title.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.outline,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((r) => _buildReminderCard(r, context, ref)).toList(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildReminderCard(ReminderModel reminder, BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTaken = reminder.status == "Taken";

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
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  final newStatus = isTaken ? "Pending" : "Taken";
                  ref.read(remindersProvider.notifier).updateReminderStatus(reminder.id, newStatus);
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isTaken ? AppTheme.secondary.withOpacity(0.12) : AppTheme.primary.withOpacity(0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isTaken ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    color: isTaken ? AppTheme.secondary : AppTheme.primary,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            reminder.medicineName,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: isDark ? Colors.white : AppTheme.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          reminder.time,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "${reminder.dosage} • ${reminder.instruction}",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 20,
                          width: 34,
                          child: Transform.scale(
                            scale: 0.7,
                            child: Switch(
                              value: reminder.isActive,
                              activeColor: AppTheme.primary,
                              onChanged: (val) {
                                ref.read(remindersProvider.notifier).toggleReminder(reminder.id);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 20),
                onPressed: () {
                  ref.read(remindersProvider.notifier).deleteReminder(reminder.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("${reminder.medicineName} deleted."),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentList(BuildContext context, WidgetRef ref, List<AppointmentModel> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_rounded, size: 64, color: AppTheme.outlineVariant.withOpacity(0.6)),
            const SizedBox(height: 16),
            Text(
              "No booked appointments",
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.outline),
            ),
          ],
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final app = list[index];
        final isCompleted = app.status == "Completed";

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white10 : AppTheme.outlineVariant.withOpacity(0.5),
            ),
            boxShadow: AppTheme.premiumShadow,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isCompleted ? AppTheme.secondary.withOpacity(0.1) : AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted ? Icons.event_available_rounded : Icons.event_note_rounded,
                color: isCompleted ? AppTheme.secondary : AppTheme.primary,
                size: 24,
              ),
            ),
            title: Text(
              app.doctorName,
              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                "${app.specialty} • ${app.dateTime}",
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.w500),
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.cancel_outlined, color: AppTheme.error, size: 20),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text("Cancel Appointment?", style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
                    content: Text(
                      "Are you sure you want to cancel appointment with ${app.doctorName}?",
                      style: GoogleFonts.inter(),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("No", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.outline)),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(remindersProvider.notifier).cancelAppointment(app.id);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Appointment cancelled."),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Text(
                          "Yes, Cancel",
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppTheme.error),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showAddMedicineDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final dosageController = TextEditingController();
    final timeController = TextEditingController();
    final instructionController = TextEditingController();
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Schedule Medicine",
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Medicine Name (e.g. Paracetamol)",
                  labelStyle: GoogleFonts.inter(fontSize: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: dosageController,
                      decoration: InputDecoration(
                        labelText: "Dosage (e.g. 650mg)",
                        labelStyle: GoogleFonts.inter(fontSize: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: timeController,
                      decoration: InputDecoration(
                        labelText: "Time (e.g. 08:00 AM)",
                        labelStyle: GoogleFonts.inter(fontSize: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: instructionController,
                decoration: InputDecoration(
                  labelText: "Instruction (e.g. 1 Tablet After Food)",
                  labelStyle: GoogleFonts.inter(fontSize: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) return;

                  await ref.read(remindersProvider.notifier).addReminder(
                    name: nameController.text.trim(),
                    dosage: dosageController.text.trim(),
                    time: timeController.text.trim(),
                    instruction: instructionController.text.trim(),
                  );

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Reminder added successfully!"),
                      backgroundColor: AppTheme.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text("Save Reminder", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBookAppointmentDialog(BuildContext context, WidgetRef ref) {
    final doctorController = TextEditingController();
    final specialtyController = TextEditingController();
    final dateController = TextEditingController(text: "2026-07-20 10:00 AM");
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Book Doctor Appointment",
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: doctorController,
                decoration: InputDecoration(
                  labelText: "Doctor Name (e.g. Dr. Ramesh Kumar)",
                  labelStyle: GoogleFonts.inter(fontSize: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: specialtyController,
                decoration: InputDecoration(
                  labelText: "Specialty (e.g. Cardiologist)",
                  labelStyle: GoogleFonts.inter(fontSize: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dateController,
                decoration: InputDecoration(
                  labelText: "Date & Time (YYYY-MM-DD HH:MM AM/PM)",
                  labelStyle: GoogleFonts.inter(fontSize: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (doctorController.text.trim().isEmpty) return;

                  await ref.read(remindersProvider.notifier).bookAppointment(
                    doctor: doctorController.text.trim(),
                    specialty: specialtyController.text.trim(),
                    dateTime: dateController.text.trim(),
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Appointment booked successfully!"),
                        backgroundColor: AppTheme.primary,
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
                  elevation: 0,
                ),
                child: Text("Book Appointment", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ],
          ),
        );
      },
    );
  }
}
