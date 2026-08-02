import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/hospital_drawer.dart';

class HospitalDashboardScreen extends StatefulWidget {
  const HospitalDashboardScreen({super.key});

  @override
  State<HospitalDashboardScreen> createState() => _HospitalDashboardScreenState();
}

class _HospitalDashboardScreenState extends State<HospitalDashboardScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  Map<String, dynamic> _metrics = {};

  @override
  void initState() {
    super.initState();
    _fetchOverview();
  }

  Future<void> _fetchOverview() async {
    try {
      final res = await _apiClient.get('/hospital/dashboard/overview');
      final raw = res.data;
      Map<String, dynamic> metrics = {};
      if (raw is Map) {
        if (raw.containsKey('data') && raw['data'] is Map) {
          metrics = Map<String, dynamic>.from(raw['data']);
        } else {
          metrics = Map<String, dynamic>.from(raw);
        }
      }
      setState(() {
        _metrics = metrics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _metrics = {};
        _isLoading = false;
      });
      // Show an error notification
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load dashboard data. Please try again.')),
      );
  }
}
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospital Overview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchOverview,
          ),
          IconButton(
            icon: const Icon(Icons.notifications_rounded),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
        ],
      ),
      drawer: const HospitalDrawer(currentRoute: '/dashboard'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderBanner(theme),
                  const SizedBox(height: 20),
                  const Text('Key Metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1.5 : 1.15,
                    children: [
                      _kpiCard('Active Patients', '${_metrics['total_patients'] ?? 0}', Icons.people_alt_rounded, const Color(0xFF0EA5E9)),
                      _kpiCard('Doctors On Duty', '${_metrics['total_doctors'] ?? 0}', Icons.medical_services_rounded, const Color(0xFF10B981)),
                      _kpiCard('Active Admissions', '${_metrics['active_admissions'] ?? 0}', Icons.single_bed_rounded, Colors.purple),
                      _kpiCard('Emergency Cases', '${_metrics['emergency_cases'] ?? 0}', Icons.emergency_rounded, Colors.red),
                      _kpiCard('Available Beds', '${_metrics['available_beds'] ?? 0}', Icons.bed_rounded, Colors.teal),
                      _kpiCard('Occupancy Rate', '${_metrics['bed_occupancy_rate'] ?? 0}%', Icons.pie_chart_rounded, Colors.amber),
                      _kpiCard('Appointments Today', '${_metrics['today_appointments'] ?? 0}', Icons.calendar_month_rounded, Colors.indigo),
                      _kpiCard('Low Stock Alerts', '${_metrics['low_stock_medicines'] ?? 0}', Icons.warning_rounded, Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Quick Operational Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/patients'),
                        icon: const Icon(Icons.person_add_rounded),
                        label: const Text('Register Patient'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/admissions'),
                        icon: const Icon(Icons.single_bed_rounded),
                        label: const Text('New Admission'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/emergency'),
                        icon: const Icon(Icons.emergency_rounded),
                        label: const Text('Emergency QR Lookup'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/analytics'),
                        icon: const Icon(Icons.psychology_rounded),
                        label: const Text('AI Risk Insights'),
                      ),
                    ],
                  )
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderBanner(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Aarogya Vault Command Center', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 6),
          Text('Real-time operational metrics, bed occupancy, emergency cases & AI risk insights.', style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                  child: Text('Live', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
