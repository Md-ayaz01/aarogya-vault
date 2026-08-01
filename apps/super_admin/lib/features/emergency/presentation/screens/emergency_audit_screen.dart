import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/super_admin_drawer.dart';

class EmergencyAuditScreen extends StatefulWidget {
  const EmergencyAuditScreen({super.key});

  @override
  State<EmergencyAuditScreen> createState() => _EmergencyAuditScreenState();
}

class _EmergencyAuditScreenState extends State<EmergencyAuditScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _cases = [];

  @override
  void initState() {
    super.initState();
    _fetchEmergency();
  }

  Future<void> _fetchEmergency() async {
    try {
      final res = await _apiClient.get('/super_admin/emergency');
      setState(() {
        _cases = res.data is List ? res.data : [];
        _isLoading = false;
      });
    } catch (e) {
    setState(() {
      _cases = [];
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency & Police Incident Surveillance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchEmergency,
          )
        ],
      ),
      drawer: const SuperAdminDrawer(currentRoute: '/emergency'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Platform Emergency Logs', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const Text('Critical trauma cases, ambulance units & medico-legal police alerts', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _cases.length,
                    itemBuilder: (context, idx) {
                      final c = _cases[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.red,
                            child: Icon(Icons.emergency_rounded, color: Colors.white),
                          ),
                          title: Text(c['patient_name'] ?? 'Emergency Case', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Unit: ${c['ambulance_unit']} | Severity: ${c['severity']}\nPolice Alert: ${c['police_notified'] ? "YES" : "NO"}'),
                          isThreeLine: true,
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
