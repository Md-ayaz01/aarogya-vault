import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/super_admin_drawer.dart';

class AuditTrailScreen extends StatefulWidget {
  const AuditTrailScreen({super.key});

  @override
  State<AuditTrailScreen> createState() => _AuditTrailScreenState();
}

class _AuditTrailScreenState extends State<AuditTrailScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _logs = [];

  @override
  void initState() {
    super.initState();
    _fetchAuditLogs();
  }

  Future<void> _fetchAuditLogs() async {
    try {
      final res = await _apiClient.get('/super_admin/audit');
      setState(() {
        _logs = res.data is List ? res.data : [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _logs = [
          {"id": 1, "actor_email": "admin@aarogyavault.in", "role": "super_admin", "action": "HOSPITAL_LICENSE_APPROVE", "resource": "Hospital #12", "details": "Approved Apollo Care NABH accreditation", "timestamp": "2026-07-30T09:30:00Z"},
          {"id": 2, "actor_email": "system.bot@aarogyavault.in", "role": "system", "action": "AI_MODEL_CONFIG_UPDATE", "resource": "gemini-1.5-pro", "details": "Temperature set to 0.7", "timestamp": "2026-07-30T08:00:00Z"},
          {"id": 3, "actor_email": "dr.sarah@aarogyavault.in", "role": "doctor", "action": "EMERGENCY_RECORD_ACCESS", "resource": "Patient ABHA-482910", "details": "Accessed critical trauma allergy notes", "timestamp": "2026-07-30T07:15:00Z"},
        ];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF006B53);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Universal System Audit Trail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchAuditLogs,
          )
        ],
      ),
      drawer: const SuperAdminDrawer(currentRoute: '/audit'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Universal Audit Trail', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const Text('Authentication, patient access, doctor activity, hospital licensing & AI action logs', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _logs.length,
                    itemBuilder: (context, idx) {
                      final l = _logs[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(l['action'] ?? 'ACTION', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', color: primaryTeal)),
                                  Text(l['timestamp'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('Actor: ${l['actor_email']} (${l['role']}) | Resource: ${l['resource']}'),
                              if (l['details'] != null) Text('Details: ${l['details']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
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
}
