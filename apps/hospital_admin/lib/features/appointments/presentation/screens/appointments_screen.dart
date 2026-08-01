import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/hospital_drawer.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _appointments = [];
  String _selectedView = "WEEKLY";

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    try {
      final res = await _apiClient.get('/hospital/appointments');
      setState(() {
        _appointments = res.data is List ? res.data : [];
        _isLoading = false;
      });
    } catch (e) {
    setState(() {
      _appointments = [];
      _isLoading = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load data from server: ${e.toString()}"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF006B53);
    const primaryContainer = Color(0xFF00A884);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments Queue & Scheduling'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchAppointments,
          )
        ],
      ),
      drawer: const HospitalDrawer(currentRoute: '/appointments'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Header & View Toggles
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Appointments Queue', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          Text('Manage patient consultations & doctor schedules', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _showBookDialog(context),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('NEW APPOINTMENT', style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),

                  // View Mode Toggle Bar
                  Row(
                    children: [
                      _viewToggleChip('WEEKLY', 'Weekly'),
                      _viewToggleChip('DAILY', 'Daily'),
                      _viewToggleChip('MONTHLY', 'Monthly'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Appointment Cards List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _appointments.length,
                    itemBuilder: (context, idx) {
                      final appt = _appointments[idx];
                      final isDone = appt['status'] == "Completed";
                      final isInProg = appt['status'] == "In-Progress";
                      final statusColor = isDone ? primaryContainer : (isInProg ? Colors.purple : primaryTeal);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: statusColor.withValues(alpha: 0.3)),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: statusColor.withValues(alpha: 0.2),
                            child: Icon(Icons.calendar_month_rounded, color: statusColor),
                          ),
                          title: Row(
                            children: [
                              Text(appt['patient_name'] ?? 'Patient', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                                child: Text(appt['specialty'] ?? 'General', style: const TextStyle(color: primaryTeal, fontSize: 10, fontWeight: FontWeight.bold)),
                              )
                            ],
                          ),
                          subtitle: Text('Doctor: ${appt['doctor_name']}\nTime Slot: ${appt['time_slot']}'),
                          isThreeLine: true,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              appt['status'] ?? 'Scheduled',
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                            ),
                          ),
                        ),
                      );
                    },
                  )
                ],
              ),
            ),
    );
  }

  Widget _viewToggleChip(String key, String title) {
    final isSelected = _selectedView == key;
    const primaryTeal = Color(0xFF006B53);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
        selected: isSelected,
        selectedColor: primaryTeal,
        labelStyle: TextStyle(color: isSelected ? Colors.white : null),
        onSelected: (val) {
          if (val) setState(() => _selectedView = key);
        },
      ),
    );
  }

  void _showBookDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Book New Consultation'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: 'Patient Name')),
            SizedBox(height: 8),
            TextField(decoration: InputDecoration(labelText: 'Doctor Specialty / Name')),
            SizedBox(height: 8),
            TextField(decoration: InputDecoration(labelText: 'Time Slot (e.g. 10:30 AM)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment booked successfully!')));
            },
            child: const Text('BOOK'),
          )
        ],
      ),
    );
  }
}
