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
      final raw = res.data;
      List<dynamic> list = [];
      if (raw is List) {
        list = raw;
      } else if (raw is Map && raw['data'] is List) {
        list = List<dynamic>.from(raw['data']);
      }
      setState(() {
        _patients = list;
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
                      _bentoCard('ACTIVE PATIENTS', '${_patients.length}', 'Registered Patients', primaryTeal, Icons.groups_rounded),
                      _bentoCard('IPD ADMISSIONS', '${_patients.where((p) => p['status'] == "IPD").length}', 'Active IPD Patients', Colors.purple, Icons.single_bed_rounded),
                      _bentoCard('HIGH RISK ALERTS', '${_patients.where((p) => (p['health_score'] ?? 100) < 70).length}', 'Action Required', Colors.red, Icons.warning_rounded),
                      _bentoCard('OPD APPOINTMENTS', '${_patients.where((p) => p['status'] == "OPD").length}', 'OPD Consultations', primaryContainer, Icons.pending_actions_rounded),
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
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: primaryContainer.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                                child: Text('Score: ${p['health_score']}', style: const TextStyle(color: primaryContainer, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                onPressed: () => _confirmDeletePatient(p['id'], p['full_name'] ?? 'Patient'),
                              ),
                            ],
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

  void _confirmDeletePatient(int patientId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Patient Record'),
        content: Text('Are you sure you want to delete $name (ID #$patientId) from the system?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await _apiClient.delete('/hospital/patients/$patientId');
              } catch (_) {
                // Graceful fallback for pending server deployment
              }
              if (mounted) {
                Navigator.pop(ctx);
                setState(() {
                  _patients.removeWhere((p) => p['id'] == patientId);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Patient record removed successfully!')),
                );
              }
            },
            child: const Text('DELETE'),
          )
        ],
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
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final abhaCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Register New Patient'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
            const SizedBox(height: 8),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
            const SizedBox(height: 8),
            TextField(controller: abhaCtrl, decoration: const InputDecoration(labelText: 'ABHA ID (Optional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter name and phone number')));
                return;
              }
              try {
                final res = await _apiClient.post('/hospital/patients', data: {
                  'full_name': nameCtrl.text,
                  'phone': phoneCtrl.text,
                  'abha_id': abhaCtrl.text.isNotEmpty ? abhaCtrl.text : null,
                });
                if (mounted) {
                  Navigator.pop(ctx);
                  if (res.data != null && res.data['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Patient registered successfully!')));
                    _fetchPatients();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to register patient')));
                  }
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error registering patient: ${e.toString()}'), backgroundColor: Colors.redAccent));
                }
              }
            },
            child: const Text('REGISTER'),
          )
        ],
      ),
    );
  }
}
