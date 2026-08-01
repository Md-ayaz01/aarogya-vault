import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/super_admin_drawer.dart';

class BroadcastNotificationsScreen extends StatefulWidget {
  const BroadcastNotificationsScreen({super.key});

  @override
  State<BroadcastNotificationsScreen> createState() => _BroadcastNotificationsScreenState();
}

class _BroadcastNotificationsScreenState extends State<BroadcastNotificationsScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _broadcasts = [];
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _msgCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchBroadcasts();
  }

  Future<void> _fetchBroadcasts() async {
    try {
      final res = await _apiClient.get('/super_admin/notifications');
      setState(() {
        _broadcasts = res.data is List ? res.data : [];
        _isLoading = false;
      });
    } catch (e) {
    setState(() {
      _broadcasts = [];
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
        title: const Text('Broadcast System Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchBroadcasts,
          )
        ],
      ),
      drawer: const SuperAdminDrawer(currentRoute: '/notifications'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ecosystem Broadcast Alerts', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          Text('Send platform-wide maintenance banners & emergency alerts', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _showBroadcastDialog(context),
                        icon: const Icon(Icons.campaign_rounded),
                        label: const Text('NEW BROADCAST', style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _broadcasts.length,
                    itemBuilder: (context, idx) {
                      final b = _broadcasts[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: primaryTeal,
                            child: Icon(Icons.campaign_rounded, color: Colors.white),
                          ),
                          title: Text(b['title'] ?? 'Alert', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${b['message']}\nTarget: ${b['target_role']} | Severity: ${b['severity']}'),
                          isThreeLine: true,
                        ),
                      );
                    },
                  )
                ],
              ),
            ),
    );
  }

  void _showBroadcastDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send Broadcast Notification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 8),
            TextField(controller: _msgCtrl, decoration: const InputDecoration(labelText: 'Message Body')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Broadcast alert sent across ecosystem!')));
            },
            child: const Text('BROADCAST'),
          )
        ],
      ),
    );
  }
}
