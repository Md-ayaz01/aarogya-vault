import 'package:flutter/material.dart';
import '../../../../shared/widgets/hospital_drawer.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {"title": "Emergency Critical Trauma Patient Received", "body": "Ambulance Unit #108 arrived with severe polytrauma patient.", "time": "10 mins ago", "type": "danger"},
      {"title": "Pharmacy Low Stock Alert", "body": "Amoxicillin 500mg has reached reorder level (18 units remaining).", "time": "25 mins ago", "type": "warning"},
      {"title": "Lab Results Ready", "body": "Complete Blood Count results ready for Patient Rajesh Kumar.", "time": "1 hour ago", "type": "info"},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications & Alerts')),
      drawer: const HospitalDrawer(currentRoute: '/notifications'),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, idx) {
          final n = notifications[idx];
          final isDanger = n['type'] == "danger";
          final isWarn = n['type'] == "warning";
          final color = isDanger ? Colors.red : (isWarn ? Colors.orange : const Color(0xFF0EA5E9));
          return Card(
            color: color.withValues(alpha: 0.1),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(
                isDanger ? Icons.emergency_rounded : (isWarn ? Icons.warning_rounded : Icons.info_rounded),
                color: color,
              ),
              title: Text(n['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${n['body']}\n${n['time']}'),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}
