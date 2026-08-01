import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/hospital_drawer.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _auditLogs = [];

  @override
  void initState() {
    super.initState();
    _fetchAuditLogs();
  }

  Future<void> _fetchAuditLogs() async {
    try {
      final res = await _apiClient.get('/hospital/settings/audit-logs');
      setState(() {
        _auditLogs = res.data is List ? res.data : [];
        _isLoading = false;
      });
    } catch (e) {
    setState(() {
      _auditLogs = [];
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
        title: const Text('RBAC Security & System Audit Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchAuditLogs,
          )
        ],
      ),
      drawer: const HospitalDrawer(currentRoute: '/settings'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Header & Save Action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('System Configuration', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          Text('Institutional hierarchies, RBAC policies & security audit trails', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryContainer,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('RBAC & System Configuration saved!')));
                        },
                        icon: const Icon(Icons.save_rounded),
                        label: const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),

                  // RBAC Matrix Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.security_rounded, color: primaryTeal),
                              SizedBox(width: 8),
                              Text('Active RBAC Permission Matrix', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _permissionRow('Hospital Dashboard View', 'hospital.dashboard.view', true),
                          _permissionRow('Patient Record Read/Write', 'hospital.patient.write', true),
                          _permissionRow('Bed & Ward Allocation', 'hospital.department.manage', true),
                          _permissionRow('Pharmacy Stock Audit', 'hospital.inventory.manage', true),
                          _permissionRow('System Security & Export Logs', 'hospital.reports.export', true),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // System Audit Logs Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('System Security Audit Trail', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('LIVE AUDIT LOGS', style: TextStyle(color: primaryTeal, fontWeight: FontWeight.bold, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _auditLogs.length,
                            itemBuilder: (context, idx) {
                              final log = _auditLogs[idx];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(log['action'] ?? 'ACTION', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace')),
                                        Text('Actor: ${log['actor']} | ${log['timestamp']}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: primaryContainer.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                                      child: Text(log['status'] ?? 'OK', style: const TextStyle(color: primaryContainer, fontWeight: FontWeight.bold, fontSize: 10)),
                                    )
                                  ],
                                ),
                              );
                            },
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
    );
  }

  Widget _permissionRow(String label, String code, bool enabled) {
    const primaryTeal = Color(0xFF006B53);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(code, style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'monospace')),
            ],
          ),
          Switch(
            value: enabled,
            activeThumbColor: primaryTeal,
            onChanged: (val) {},
          )
        ],
      ),
    );
  }
}
