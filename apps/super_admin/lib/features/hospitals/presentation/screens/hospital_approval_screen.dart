import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/super_admin_drawer.dart';

class HospitalApprovalScreen extends StatefulWidget {
  const HospitalApprovalScreen({super.key});

  @override
  State<HospitalApprovalScreen> createState() => _HospitalApprovalScreenState();
}

class _HospitalApprovalScreenState extends State<HospitalApprovalScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _requests = [];

  @override
  void initState() {
    super.initState();
    _fetchHospitalRequests();
  }

  Future<void> _fetchHospitalRequests() async {
    try {
      final res = await _apiClient.get('/super_admin/hospitals');
      setState(() {
        _requests = res.data is List ? res.data : [];
        _isLoading = false;
      });
    } catch (e) {
    setState(() {
      _requests = [];
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
    const primaryContainer = Color(0xFF00A884);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospital Licensing & Approvals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchHospitalRequests,
          )
        ],
      ),
      drawer: const SuperAdminDrawer(currentRoute: '/hospitals'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Hospital License Approvals', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const Text('Review accreditation, NABH registration & PM-JAY integration', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _requests.length,
                    itemBuilder: (context, idx) {
                      final req = _requests[idx];
                      final isPending = req['status'] == "Pending";
                      final isApproved = req['status'] == "Approved";
                      final statusColor = isApproved ? primaryContainer : (isPending ? Colors.orange : Colors.red);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: statusColor.withValues(alpha: 0.2),
                            child: Icon(Icons.local_hospital_rounded, color: statusColor),
                          ),
                          title: Row(
                            children: [
                              Text(req['hospital_name'] ?? 'Hospital', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                                child: Text(req['status'] ?? 'Pending', style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                              )
                            ],
                          ),
                          subtitle: Text('License: ${req['license_number']} | Notes: ${req['notes']}'),
                          trailing: isPending
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.check_circle_rounded, color: primaryContainer),
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Approved ${req['hospital_name']}')));
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.cancel_rounded, color: Colors.red),
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rejected ${req['hospital_name']}')));
                                      },
                                    ),
                                  ],
                                )
                              : Text(req['status'], style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
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
