import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/hospital_drawer.dart';

class AdmissionsScreen extends StatefulWidget {
  const AdmissionsScreen({super.key});

  @override
  State<AdmissionsScreen> createState() => _AdmissionsScreenState();
}

class _AdmissionsScreenState extends State<AdmissionsScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _admissions = [];

  @override
  void initState() {
    super.initState();
    _fetchAdmissions();
  }

  Future<void> _fetchAdmissions() async {
    try {
      final res = await _apiClient.get('/hospital/admissions');
      setState(() {
        _admissions = res.data is List ? res.data : [];
        _isLoading = false;
      });
    } catch (e) {
    setState(() {
      _admissions = [];
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
      appBar: AppBar(title: const Text('Patient Admissions (IPD/OPD)')),
      drawer: const HospitalDrawer(currentRoute: '/admissions'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _admissions.length,
              itemBuilder: (context, idx) {
                final a = _admissions[idx];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.single_bed_rounded)),
                    title: Text(a['patient_name'] ?? 'Patient', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Dept: ${a['department_name']} | Doctor: ${a['doctor_name']}\nBed: ${a['bed_number']} (${a['admission_type']})'),
                    isThreeLine: true,
                    trailing: Chip(
                      label: Text(a['status'] ?? 'Admitted', style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold)),
                      backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
