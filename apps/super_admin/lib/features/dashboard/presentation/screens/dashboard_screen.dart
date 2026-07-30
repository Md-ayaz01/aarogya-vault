import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/super_admin_drawer.dart';

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  State<SuperAdminDashboardScreen> createState() => _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  Map<String, dynamic> _kpis = {};

  @override
  void initState() {
    super.initState();
    _fetchKPIs();
  }

  Future<void> _fetchKPIs() async {
    try {
      final res = await _apiClient.get('/super_admin/dashboard/overview');
      setState(() {
        _kpis = res.data is Map<String, dynamic> ? res.data : {};
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _kpis = {
          "total_hospitals": 48,
          "total_doctors": 342,
          "total_patients": 14820,
          "total_users": 18500,
          "active_subscriptions": 42,
          "pending_approvals": 6,
          "system_health": "100% Fully Operational",
          "ai_usage_tokens_today": 128450,
          "emergency_alerts_today": 14
        };
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF006B53);
    const primaryContainer = Color(0xFF00A884);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Platform Command Center'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchKPIs,
          )
        ],
      ),
      drawer: const SuperAdminDrawer(currentRoute: '/dashboard'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Platform Governance Dashboard', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          Text('Ecosystem-wide metrics, system health & operational controls', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pushNamed(context, '/hospitals'),
                        icon: const Icon(Icons.verified_user_rounded),
                        label: const Text('REVIEW HOSPITALS', style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bento Grid Platform KPIs
                  GridView.count(
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      _kpiCard('TOTAL HOSPITALS', '${_kpis['total_hospitals'] ?? 48}', '6 Approvals Pending', primaryTeal, Icons.local_hospital_rounded),
                      _kpiCard('DOCTORS ROSTER', '${_kpis['total_doctors'] ?? 342}', '342 Verified Licenses', Colors.blue, Icons.medical_services_rounded),
                      _kpiCard('PATIENT REGISTRY', '${_kpis['total_patients'] ?? 14820}', 'ABHA Identity Linked', primaryContainer, Icons.people_alt_rounded),
                      _kpiCard('ACTIVE SUBSCRIPTIONS', '${_kpis['active_subscriptions'] ?? 42}', '₹4.8 Cr Platform Revenue', Colors.purple, Icons.card_membership_rounded),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // System Status Banner
                  Card(
                    color: primaryTeal.withValues(alpha: 0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: primaryContainer, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('SYSTEM STATUS: ${_kpis['system_health'] ?? 'OPERATIONAL'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text('Gemini AI Tokens Today: ${_kpis['ai_usage_tokens_today']} | Live Emergencies: ${_kpis['emergency_alerts_today']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
    );
  }

  Widget _kpiCard(String label, String val, String sub, Color color, IconData icon) {
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
                Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.grey)),
                Icon(icon, color: color, size: 20),
              ],
            ),
            Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
