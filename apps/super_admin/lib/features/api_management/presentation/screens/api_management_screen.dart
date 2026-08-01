import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/super_admin_drawer.dart';

class APIManagementScreen extends StatefulWidget {
  const APIManagementScreen({super.key});

  @override
  State<APIManagementScreen> createState() => _APIManagementScreenState();
}

class _APIManagementScreenState extends State<APIManagementScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _apiKeys = [];

  @override
  void initState() {
    super.initState();
    _fetchApiKeys();
  }

  Future<void> _fetchApiKeys() async {
    try {
      final res = await _apiClient.get('/super_admin/api-keys');
      setState(() {
        _apiKeys = res.data is List ? res.data : [];
        _isLoading = false;
      });
    } catch (e) {
    setState(() {
      _apiKeys = [];
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
        title: const Text('API Management & Webhooks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchApiKeys,
          )
        ],
      ),
      drawer: const SuperAdminDrawer(currentRoute: '/api-management'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Platform API Keys & Rate Limits', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const Text('Manage integration client keys, rate limits & emergency webhooks', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _apiKeys.length,
                    itemBuilder: (context, idx) {
                      final k = _apiKeys[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(Icons.api_rounded, color: primaryTeal),
                          title: Text(k['client_name'] ?? 'Client', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Rate Limit: ${k['rate_limit']} req/min | Created: ${k['created_at']}'),
                          trailing: Switch(
                            value: k['is_active'] == true,
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
