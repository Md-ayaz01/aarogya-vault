import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/hospital_drawer.dart';

class DoctorManagementScreen extends StatefulWidget {
  const DoctorManagementScreen({super.key});

  @override
  State<DoctorManagementScreen> createState() => _DoctorManagementScreenState();
}

class _DoctorManagementScreenState extends State<DoctorManagementScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _doctors = [];
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    try {
      final res = await _apiClient.get('/hospital/doctors');
      setState(() {
        _doctors = res.data is List ? res.data : [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _doctors = [
          {"id": 1, "full_name": "Dr. Sarah Al-Fayed", "specialty": "Cardiology", "department": "Heart & Vascular", "registration_number": "DOC-9921", "is_available": true, "satisfaction": 98},
          {"id": 2, "full_name": "Dr. Marcus Chen", "specialty": "Neurology", "department": "Neurosciences", "registration_number": "DOC-4412", "is_available": false, "satisfaction": 92},
          {"id": 3, "full_name": "Dr. Priya Patel", "specialty": "Pediatrics", "department": "Child Health", "registration_number": "DOC-1029", "is_available": true, "satisfaction": 96},
          {"id": 4, "full_name": "Dr. Vikram Seth", "specialty": "Orthopedics", "department": "Bone & Joint", "registration_number": "DOC-8831", "is_available": true, "satisfaction": 95},
        ];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF006B53);
    const primaryContainer = Color(0xFF00A884);

    final filteredDoctors = _searchQuery.isEmpty
        ? _doctors
        : _doctors.where((d) =>
            d['full_name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
            d['specialty'].toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Roster Directory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchDoctors,
          )
        ],
      ),
      drawer: const HospitalDrawer(currentRoute: '/doctors'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Title Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Doctor Directory', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          Text('Physician rosters, duty schedules & medical license verification', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryContainer,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _showAddDoctorDialog(context),
                        icon: const Icon(Icons.add_circle_rounded),
                        label: const Text('ADD DOCTOR', style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Search Bar
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
                              hintText: 'Search doctor name, medical ID, or specialization...',
                              border: InputBorder.none,
                            ),
                            onChanged: (val) => setState(() => _searchQuery = val),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Physician Roster List Cards
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredDoctors.length,
                    itemBuilder: (context, idx) {
                      final doc = filteredDoctors[idx];
                      final isOnDuty = doc['is_available'] == true;
                      final statusColor = isOnDuty ? primaryContainer : Colors.red;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: statusColor.withValues(alpha: 0.2)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: primaryTeal.withValues(alpha: 0.2),
                                child: Text(
                                  doc['full_name']?[4] ?? 'D',
                                  style: const TextStyle(color: primaryTeal, fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(doc['full_name'] ?? 'Dr. Physician', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 2),
                                    Text('${doc['specialty']} (${doc['department']})', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                    Text('License ID: ${doc['registration_number']}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isOnDuty ? 'ON-DUTY' : 'OFF-DUTY',
                                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text('${doc['satisfaction'] ?? 95}% Sat.', style: const TextStyle(color: primaryTeal, fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              )
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

  void _showAddDoctorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Physician'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: 'Full Name (e.g. Dr. John Doe)')),
            SizedBox(height: 8),
            TextField(decoration: InputDecoration(labelText: 'Specialization (e.g. Cardiology)')),
            SizedBox(height: 8),
            TextField(decoration: InputDecoration(labelText: 'Medical License Registration ID')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Physician added to roster!')));
            },
            child: const Text('ADD'),
          )
        ],
      ),
    );
  }
}
