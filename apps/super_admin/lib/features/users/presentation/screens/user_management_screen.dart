import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/super_admin_drawer.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final res = await _apiClient.get('/super_admin/users');
      setState(() {
        _users = res.data is List ? res.data : [];
        _isLoading = false;
      });
    } catch (e) {
    setState(() {
      _users = [];
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
        title: const Text('Ecosystem User Governance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchUsers,
          )
        ],
      ),
      drawer: const SuperAdminDrawer(currentRoute: '/users'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Platform User Accounts', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const Text('Manage all patients, doctors, hospital admins & system super admins', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _users.length,
                    itemBuilder: (context, idx) {
                      final u = _users[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: primaryTeal.withValues(alpha: 0.2),
                            child: const Icon(Icons.person_rounded, color: primaryTeal),
                          ),
                          title: Text(u['email'] ?? u['phone'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Role: ${u['role'].toString().toUpperCase()} | Status: ${u['status']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_rounded, color: primaryTeal),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Editing user permissions for ${u['email']}')));
                            },
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
