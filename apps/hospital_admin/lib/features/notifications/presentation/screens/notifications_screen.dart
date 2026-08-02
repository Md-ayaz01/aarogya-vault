import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/hospital_drawer.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final res = await _apiClient.get('/hospital/notifications');
      final raw = res.data;
      List<dynamic> list = [];
      if (raw is List) {
        list = raw;
      } else if (raw is Map && raw['data'] is List) {
        list = List<dynamic>.from(raw['data']);
      }
      setState(() {
        _notifications = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _notifications = [];
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to load notifications: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications & Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchNotifications,
          )
        ],
      ),
      drawer: const HospitalDrawer(currentRoute: '/notifications'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Text(
                    'No notifications found.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, idx) {
                    final n = _notifications[idx];
                    final isDanger = n['type'] == "danger";
                    final isWarn = n['type'] == "warning";
                    final color = isDanger
                        ? Colors.red
                        : (isWarn ? Colors.orange : const Color(0xFF0EA5E9));
                    return Card(
                      color: color.withValues(alpha: 0.1),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(
                          isDanger
                              ? Icons.emergency_rounded
                              : (isWarn ? Icons.warning_rounded : Icons.info_rounded),
                          color: color,
                        ),
                        title: Text(n['title'] ?? 'Notification', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${n['body'] ?? ""}\n${n['time'] ?? ""}'),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}
