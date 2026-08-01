import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/super_admin_drawer.dart';

class PatientMasterScreen extends StatefulWidget {
  const PatientMasterScreen({super.key});

  @override
  State<PatientMasterScreen> createState() => _PatientMasterScreenState();
}

class _PatientMasterScreenState extends State<PatientMasterScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _patients = [];

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    try {
      final res = await _apiClient.get('/super_admin/patients');
      setState(() {
        _patients = res.data is List ? res.data : [];
        _isLoading = false;
      });
    } catch (e) {
    setState(() {
      _patients = [];
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Patient Identity Registry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchPatients,
          )
        ],
      ),
      drawer: const SuperAdminDrawer(currentRoute: '/patients'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Master Patient Registry', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const Text('ABHA identity status, emergency record logs & consent settings', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _patients.length,
                    itemBuilder: (context, idx) {
                      final p = _patients[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: primaryTeal.withValues(alpha: 0.2),
                            child: Text(p['full_name']?[0] ?? 'P', style: const TextStyle(color: primaryTeal, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(p['full_name'] ?? 'Patient', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('ABHA ID: ${p['abha_id']} | Phone: ${p['phone']}\nBlood: ${p['blood_group']} | Gender: ${p['gender']}'),
                          isThreeLine: true,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                            child: Text(p['status'] ?? 'Active', style: const TextStyle(color: primaryTeal, fontWeight: FontWeight.bold, fontSize: 10)),
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
