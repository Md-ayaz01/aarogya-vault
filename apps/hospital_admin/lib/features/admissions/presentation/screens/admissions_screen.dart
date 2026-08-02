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
      final raw = res.data;
      List<dynamic> list = [];
      if (raw is List) {
        list = raw;
      } else if (raw is Map && raw['data'] is List) {
        list = List<dynamic>.from(raw['data']);
      }
      setState(() {
        _admissions = list;
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
      appBar: AppBar(
        title: const Text('Patient Admissions (IPD/OPD)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchAdmissions,
          )
        ],
      ),
      drawer: const HospitalDrawer(currentRoute: '/admissions'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewAdmissionDialog(context),
        backgroundColor: const Color(0xFF00A884),
        icon: const Icon(Icons.single_bed_rounded, color: Colors.white),
        label: const Text('NEW ADMISSION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _admissions.isEmpty
              ? const Center(child: Text('No active admissions found.', style: TextStyle(color: Colors.grey, fontSize: 16)))
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

  void _showNewAdmissionDialog(BuildContext context) {
    final patientIdCtrl = TextEditingController(text: "1");
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Process New IPD/OPD Admission'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: patientIdCtrl, decoration: const InputDecoration(labelText: 'Patient User ID'), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Admission Notes / Triage')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              if (patientIdCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter patient ID')));
                return;
              }
              try {
                final res = await _apiClient.post('/hospital/admissions', data: {
                  'patient_id': int.tryParse(patientIdCtrl.text) ?? 1,
                  'admission_type': 'IPD',
                  'notes': notesCtrl.text.isNotEmpty ? notesCtrl.text : 'Routine Admission'
                });
                if (mounted) {
                  Navigator.pop(ctx);
                  if (res.data != null && res.data['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Patient Admitted Successfully!')));
                    _fetchAdmissions();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to process admission')));
                  }
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.redAccent));
                }
              }
            },
            child: const Text('ADMIT PATIENT'),
          )
        ],
      ),
    );
  }
}
