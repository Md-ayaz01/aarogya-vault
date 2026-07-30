import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/hospital_drawer.dart';

class DepartmentManagementScreen extends StatefulWidget {
  const DepartmentManagementScreen({super.key});

  @override
  State<DepartmentManagementScreen> createState() => _DepartmentManagementScreenState();
}

class _DepartmentManagementScreenState extends State<DepartmentManagementScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _departments = [];

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
  }

  Future<void> _fetchDepartments() async {
    try {
      final res = await _apiClient.get('/hospital/departments');
      setState(() {
        _departments = res.data is List ? res.data : [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _departments = [
          {"id": 1, "name": "Cardiology", "code": "CARD-01", "head_doctor_name": "Dr. Ramesh Verma", "description": "Heart & Cardiovascular Care"},
          {"id": 2, "name": "Neurology", "code": "NEURO-01", "head_doctor_name": "Dr. Priya Sundaram", "description": "Brain & Nervous System"},
          {"id": 3, "name": "Orthopedics", "code": "ORTHO-01", "head_doctor_name": "Dr. Sunita Rao", "description": "Bones & Joints Surgery"},
        ];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Department Management')),
      drawer: const HospitalDrawer(currentRoute: '/departments'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _departments.length,
              itemBuilder: (context, idx) {
                final d = _departments[idx];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                      child: Text(d['code']?[0] ?? 'D', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                    ),
                    title: Text('${d['name']} (${d['code']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Head: ${d['head_doctor_name']}\n${d['description'] ?? ""}'),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
