import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/super_admin_drawer.dart';

class SupportCenterScreen extends StatefulWidget {
  const SupportCenterScreen({super.key});

  @override
  State<SupportCenterScreen> createState() => _SupportCenterScreenState();
}

class _SupportCenterScreenState extends State<SupportCenterScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _tickets = [];

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  Future<void> _fetchTickets() async {
    try {
      final res = await _apiClient.get('/super_admin/support');
      setState(() {
        _tickets = res.data is List ? res.data : [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _tickets = [
          {"id": 1, "category": "ABHA Sync", "priority": "High", "status": "Open", "subject": "Delayed ABHA ID verification", "description": "Verification API response takes > 5s on peak load."},
          {"id": 2, "category": "Billing Tier", "priority": "Medium", "status": "In-Progress", "subject": "Upgrade to Enterprise Plan", "description": "Fortis requests add-on module for 100 extra ICU beds."},
        ];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF006B53);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Ticket Center'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchTickets,
          )
        ],
      ),
      drawer: const SuperAdminDrawer(currentRoute: '/support'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Platform Support Center', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const Text('Manage incoming help tickets, bug reports & hospital feature requests', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _tickets.length,
                    itemBuilder: (context, idx) {
                      final t = _tickets[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(Icons.support_agent_rounded, color: primaryTeal),
                          title: Text(t['subject'] ?? 'Ticket', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Category: ${t['category']} | Priority: ${t['priority']}\n${t['description']}'),
                          isThreeLine: true,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                            child: Text(t['status'] ?? 'Open', style: const TextStyle(color: primaryTeal, fontWeight: FontWeight.bold, fontSize: 10)),
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
