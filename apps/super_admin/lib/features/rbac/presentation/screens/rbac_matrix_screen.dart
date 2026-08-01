import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/super_admin_drawer.dart';

class RBACMatrixScreen extends StatefulWidget {
  const RBACMatrixScreen({super.key});

  @override
  State<RBACMatrixScreen> createState() => _RBACMatrixScreenState();
}

class _RBACMatrixScreenState extends State<RBACMatrixScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _matrix = [];

  @override
  void initState() {
    super.initState();
    _fetchRBAC();
  }

  Future<void> _fetchRBAC() async {
    try {
      final res = await _apiClient.get('/super_admin/rbac');
      setState(() {
        _matrix = res.data is List ? res.data : [];
        _isLoading = false;
      });
    } catch (e) {
    setState(() {
      _matrix = [];
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
        title: const Text('RBAC Matrix & Permission Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchRBAC,
          )
        ],
      ),
      drawer: const SuperAdminDrawer(currentRoute: '/rbac'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Platform RBAC Matrix', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const Text('Role-based permissions matrix for Super Admin, Hospital Admin, Doctor & Patient', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _matrix.length,
                    itemBuilder: (context, idx) {
                      final item = _matrix[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(Icons.security_rounded, color: primaryTeal),
                          title: Text('Role: ${item['role_name'].toString().toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Permission Key: ${item['permission_key']}', style: const TextStyle(fontFamily: 'monospace')),
                          trailing: Switch(
                            value: true,
                            activeThumbColor: primaryTeal,
                            onChanged: (val) {},
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
