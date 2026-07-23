import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/network/api_client.dart';

class Appointment {
  final int id;
  final String patientName;
  final DateTime startTime;
  final String type;
  final String status;
  final int patientId;
  final bool hasAccess;

  Appointment({
    required this.id,
    required this.patientName,
    required this.startTime,
    required this.type,
    required this.status,
    required this.patientId,
    required this.hasAccess,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final rawDateTime = (json['start_time'] ?? json['date_time']) as String;
    return Appointment(
      id: json['id'] as int,
      patientName: json['patient_name'] as String,
      startTime: _parseDateTime(rawDateTime),
      type: (json['type'] ?? json['specialty'] ?? 'Appointment') as String,
      status: json['status'] as String,
      patientId: json['patient_id'] as int,
      hasAccess: json['has_access'] as bool? ?? false,
    );
  }

  static DateTime _parseDateTime(String value) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      try {
        return DateFormat('yyyy-MM-dd hh:mm a').parse(value);
      } catch (_) {
        return DateFormat('yyyy-MM-dd HH:mm').parse(value);
      }
    }
  }
}

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({Key? key}) : super(key: key);

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  late Future<List<Appointment>> _appointmentsFuture;
  String _selectedTab = 'TODAY';

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  void _loadAppointments() {
    _appointmentsFuture = fetchAppointments();
  }

  Future<List<Appointment>> fetchAppointments() async {
    final response = await getIt<ApiClient>().get('/doctor/appointments');
    if (response.statusCode == 200) {
      final List<dynamic> list = response.data as List<dynamic>;
      return list.map((e) => Appointment.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load appointments');
    }
  }

  Future<void> _updateStatus(int appointmentId, String newStatus) async {
    final response = await getIt<ApiClient>().patch(
      '/doctor/appointments/$appointmentId/status',
      queryParameters: {'status': newStatus},
    );
    if (response.statusCode == 200) {
      setState(() {
        _loadAppointments();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment updated to $newStatus successfully'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update status')),
      );
    }
  }

  List<Appointment> _filterAppointments(List<Appointment> all) {
    final now = DateTime.now();
    switch (_selectedTab) {
      case 'TODAY':
        return all.where((a) => a.startTime.year == now.year && a.startTime.month == now.month && a.startTime.day == now.day).toList();
      case 'UPCOMING':
        return all.where((a) => a.startTime.isAfter(now) && a.status == 'Upcoming').toList();
      case 'COMPLETED':
        return all.where((a) => a.status == 'Completed').toList();
      case 'CANCELLED':
        return all.where((a) => a.status == 'Cancelled').toList();
      default:
        return all;
    }
  }

  void _showLockedAccessDialog(int patientId, String patientName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock_outline_rounded, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            const Text('Access Locked'),
          ],
        ),
        content: Text('You do not have active consent to access $patientName\'s profile. Please scan their Emergency QR or ask them to grant consent.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/qr-scanner');
            },
            child: const Text('Scan QR'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appt) {
    final timeStr = DateFormat.Hm().format(appt.startTime);
    final dateStr = DateFormat.yMMMMd().format(appt.startTime);
    final primary = Theme.of(context).colorScheme.primary;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: primary.withOpacity(0.1),
                  child: Text(
                    appt.patientName.isNotEmpty ? appt.patientName[0].toUpperCase() : 'P',
                    style: TextStyle(color: primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appt.patientName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text('$dateStr • $timeStr • ${appt.type}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: appt.status == 'Completed'
                        ? Colors.green.shade50
                        : (appt.status == 'Cancelled' ? Colors.red.shade50 : Colors.blue.shade50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    appt.status,
                    style: TextStyle(
                      color: appt.status == 'Completed'
                          ? Colors.green.shade700
                          : (appt.status == 'Cancelled' ? Colors.red.shade700 : Colors.blue.shade700),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: Colors.grey.shade100),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (appt.hasAccess) ...[
                  TextButton.icon(
                    icon: const Icon(Icons.analytics_outlined, size: 16),
                    label: const Text('CHART'),
                    onPressed: () {
                      Navigator.pushNamed(context, '/timeline', arguments: {'patientId': appt.patientId});
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                TextButton.icon(
                  icon: Icon(appt.hasAccess ? Icons.assignment_ind_outlined : Icons.lock_outline, size: 16),
                  label: const Text('DETAILS'),
                  onPressed: () {
                    if (appt.hasAccess) {
                      Navigator.pushNamed(context, '/patient-profile', arguments: {'patientId': appt.patientId});
                    } else {
                      _showLockedAccessDialog(appt.patientId, appt.patientName);
                    }
                  },
                ),
                const SizedBox(width: 8),
                if (appt.status == 'Upcoming') ...[
                  ElevatedButton(
                    onPressed: () => _updateStatus(appt.id, 'Completed'),
                    child: const Text('ADMIT'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _updateStatus(appt.id, 'Cancelled'),
                    child: const Text('CANCEL'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Appointments'),
          bottom: TabBar(
            onTap: (index) {
              setState(() {
                _selectedTab = ['TODAY', 'UPCOMING', 'COMPLETED', 'CANCELLED'][index];
              });
            },
            tabs: const [
              Tab(text: 'TODAY'),
              Tab(text: 'UPCOMING'),
              Tab(text: 'COMPLETED'),
              Tab(text: 'CANCELLED'),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _loadAppointments();
            });
            await _appointmentsFuture;
          },
          child: FutureBuilder<List<Appointment>>(
            future: _appointmentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 48, color: Theme.of(context).colorScheme.error),
                        const SizedBox(height: 16),
                        Text('Error loading appointments: ${snapshot.error}', textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text('No appointments scheduled'),
                );
              }
              final filtered = _filterAppointments(snapshot.data!);
              if (filtered.isEmpty) {
                return const Center(
                  child: Text('No appointments in this category'),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: filtered.length,
                itemBuilder: (context, index) => _buildAppointmentCard(filtered[index]),
              );
            },
          ),
        ),
      ),
    );
  }
}
