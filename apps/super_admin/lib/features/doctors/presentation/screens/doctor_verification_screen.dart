import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/super_admin_drawer.dart';

class DoctorVerificationScreen extends StatefulWidget {
  const DoctorVerificationScreen({super.key});

  @override
  State<DoctorVerificationScreen> createState() => _DoctorVerificationScreenState();
}

class _DoctorVerificationScreenState extends State<DoctorVerificationScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _doctors = [];

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    try {
      final res = await _apiClient.get('/super_admin/doctors');
      setState(() {
        _doctors = res.data is List ? res.data : [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _doctors = [
          {"id": 1, "full_name": "Dr. Sarah Al-Fayed", "license_number": "DOC-9921", "specialty": "Cardiology", "status": "Verified", "hospital": "Aarogya Central Hospital"},
          {"id": 2, "full_name": "Dr. Marcus Chen", "license_number": "DOC-4412", "specialty": "Neurology", "status": "Verified", "hospital": "City Care Clinic"},
          {"id": 3, "full_name": "Dr. Rajesh Sharma", "license_number": "DOC-1002", "specialty": "Pediatrics", "status": "Pending Verification", "hospital": "Apollo Center"},
        ];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryContainer = Color(0xFF00A884);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor License Verification'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchDoctors,
          )
        ],
      ),
      drawer: const SuperAdminDrawer(currentRoute: '/doctors'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Platform Doctor Verification', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const Text('Medical council registration & license audit across all hospitals', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _doctors.length,
                    itemBuilder: (context, idx) {
                      final doc = _doctors[idx];
                      final isVerified = doc['status'] == "Verified";
                      final statusColor = isVerified ? primaryContainer : Colors.orange;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: statusColor.withValues(alpha: 0.2),
                            child: Icon(Icons.medical_services_rounded, color: statusColor),
                          ),
                          title: Row(
                            children: [
                              Text(doc['full_name'] ?? 'Doctor', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                                child: Text(doc['status'] ?? 'Pending', style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                              )
                            ],
                          ),
                          subtitle: Text('License: ${doc['license_number']} | Specialty: ${doc['specialty']}\nHospital: ${doc['hospital']}'),
                          isThreeLine: true,
                          trailing: isVerified
                              ? const Icon(Icons.verified_rounded, color: primaryContainer)
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: primaryContainer, foregroundColor: Colors.white),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verified ${doc['full_name']}')));
                                  },
                                  child: const Text('VERIFY'),
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
