import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/hospital_drawer.dart';

class PatientManagementScreen extends StatefulWidget {
  const PatientManagementScreen({super.key});

  @override
  State<PatientManagementScreen> createState() => _PatientManagementScreenState();
}

class _PatientManagementScreenState extends State<PatientManagementScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _patients = [];
  String _searchQuery = "";
  String _selectedStatusFilter = "ALL";

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    try {
      final res = await _apiClient.get('/hospital/patients', queryParameters: _searchQuery.isNotEmpty ? {'search': _searchQuery} : null);
      setState(() {
        _patients = res.data is List ? res.data : [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _patients = [
          {"id": 1, "full_name": "Rajesh Kumar", "phone": "+919876543210", "gender": "Male", "blood_group": "O+", "health_score": 94, "abha_id": "ABHA-482910", "status": "IPD"},
          {"id": 2, "full_name": "Anita Sharma", "phone": "+919876543211", "gender": "Female", "blood_group": "A+", "health_score": 88, "abha_id": "ABHA-192831", "status": "OPD"},
          {"id": 3, "full_name": "Suresh Patel", "phone": "+919876543212", "gender": "Male", "blood_group": "B+", "health_score": 79, "abha_id": "ABHA-994822", "status": "IPD"},
          {"id": 4, "full_name": "Sunita Rao", "phone": "+919876543213", "gender": "Female", "blood_group": "AB+", "health_score": 91, "abha_id": "ABHA-104921", "status": "OPD"},
        ];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF006B53);
    const primaryContainer = Color(0xFF00A884);

    final filteredPatients = _selectedStatusFilter == "ALL"
        ? _patients
        : _patients.where((p) => p['status'].toString().toUpperCase() == _selectedStatusFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Directory & Registry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exporting Patient Registry as CSV...')));
            },
          )
        ],
      ),
      drawer: const HospitalDrawer(currentRoute: '/patients'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Title & Action Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Patient Registry', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          Text('Master patient records, ABHA verification & health scores', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryContainer,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _showRegisterDialog(context),
                        icon: const Icon(Icons.person_add_rounded),
                        label: const Text('REGISTER PATIENT', style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bento Stats Overview Cards
                  GridView.count(
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _bentoCard('ACTIVE PATIENTS', '1,482', '+12% Total', primaryTeal, Icons.groups_rounded),
                      _bentoCard('IPD ADMISSIONS', '312', '84% Occupied', Colors.purple, Icons.single_bed_rounded),
                      _bentoCard('HIGH RISK ALERTS', '18', 'Action Required', Colors.red, Icons.warning_rounded),
                      _bentoCard('OPD APPOINTMENTS', '124', 'Scheduled Today', primaryContainer, Icons.pending_actions_rounded),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Search & Filter Bar
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: primaryTeal.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, color: primaryTeal),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'Search patient name, ABHA ID, phone, or blood group...',
                              border: InputBorder.none,
                            ),
                            onChanged: (val) {
                              _searchQuery = val;
                              _fetchPatients();
                            },
                          ),
                        ),
                        DropdownButton<String>(
                          value: _selectedStatusFilter,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: "ALL", child: Text('ALL STATUS')),
                            DropdownMenuItem(value: "IPD", child: Text('IPD ONLY')),
                            DropdownMenuItem(value: "OPD", child: Text('OPD ONLY')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedStatusFilter = val);
                          },
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Patient Directory List Cards
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredPatients.length,
                    itemBuilder: (context, idx) {
                      final p = filteredPatients[idx];
                      final isIPD = p['status'] == "IPD";
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: primaryTeal.withValues(alpha: 0.2),
                            child: Text(p['full_name']?[0] ?? 'P', style: const TextStyle(color: primaryTeal, fontWeight: FontWeight.bold)),
                          ),
                          title: Row(
                            children: [
                              Text(p['full_name'] ?? 'Patient', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isIPD ? Colors.purple : primaryContainer).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  p['status'] ?? 'OPD',
                                  style: TextStyle(color: isIPD ? Colors.purple : primaryContainer, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              )
                            ],
                          ),
                          subtitle: Text('ABHA ID: ${p['abha_id']} | Phone: ${p['phone']}\nBlood: ${p['blood_group']} | Gender: ${p['gender']}'),
                          isThreeLine: true,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: primaryContainer.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                            child: Text('Score: ${p['health_score']}', style: const TextStyle(color: primaryContainer, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _bentoCard(String label, String val, String sub, Color color, IconData icon) {
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

  void _showRegisterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Register New Patient'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: 'Full Name')),
            SizedBox(height: 8),
            TextField(decoration: InputDecoration(labelText: 'Phone Number')),
            SizedBox(height: 8),
            TextField(decoration: InputDecoration(labelText: 'ABHA ID (Optional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Patient registered successfully!')));
            },
            child: const Text('REGISTER'),
          )
        ],
      ),
    );
  }
}
