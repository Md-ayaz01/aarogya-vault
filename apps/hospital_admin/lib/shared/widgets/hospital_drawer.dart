import 'package:flutter/material.dart';
import '../../core/database/local_db.dart';

class HospitalDrawer extends StatelessWidget {
  final String currentRoute;
  const HospitalDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const activeColor = Color(0xFF79F9D0);
    const primaryTeal = Color(0xFF006B53);

    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: primaryTeal,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.local_hospital_rounded, color: activeColor, size: 28),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aarogya Vault',
                          style: TextStyle(color: activeColor, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'ADMIN TERMINAL',
                          style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _drawerTile(context, 'Dashboard', Icons.dashboard_rounded, '/dashboard'),
                _drawerTile(context, 'Patients Directory', Icons.people_alt_rounded, '/patients'),
                _drawerTile(context, 'Doctors Roster', Icons.medical_services_rounded, '/doctors'),
                _drawerTile(context, 'Departments', Icons.business_rounded, '/departments'),
                _drawerTile(context, 'Admissions (IPD/OPD)', Icons.single_bed_rounded, '/admissions'),
                _drawerTile(context, 'Ward & Bed Allocation', Icons.bed_rounded, '/beds'),
                _drawerTile(context, 'Appointments Queue', Icons.calendar_month_rounded, '/appointments'),
                _drawerTile(context, 'Laboratory Orders', Icons.biotech_rounded, '/laboratory'),
                _drawerTile(context, 'Radiology Imaging', Icons.monitor_weight_rounded, '/radiology'),
                _drawerTile(context, 'Pharmacy Stock', Icons.local_pharmacy_rounded, '/pharmacy'),
                _drawerTile(context, 'Emergency Triage', Icons.emergency_rounded, '/emergency'),
                _drawerTile(context, 'AI Clinical Insights', Icons.psychology_rounded, '/analytics'),
                _drawerTile(context, 'Operational Reports', Icons.assessment_rounded, '/reports'),
                _drawerTile(context, 'Alerts & Notifications', Icons.notifications_active_rounded, '/notifications'),
                const Divider(),
                _drawerTile(context, 'RBAC Settings & Logs', Icons.security_rounded, '/settings'),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryTeal.withValues(alpha: 0.1),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: primaryTeal,
                  child: Text('AT', style: TextStyle(color: activeColor, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dr. Aris Thorne', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('Chief Administrator', style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.red),
                  onPressed: () async {
                    await LocalDB.deleteToken();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _drawerTile(BuildContext context, String title, IconData icon, String route) {
    final isSelected = currentRoute == route;
    const activeColor = Color(0xFF79F9D0);
    const primaryTeal = Color(0xFF006B53);

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? primaryTeal.withValues(alpha: 0.2) : Colors.transparent,
        border: Border(
          left: BorderSide(
            color: isSelected ? activeColor : Colors.transparent,
            width: 4,
          ),
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? activeColor : Colors.grey),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? activeColor : null,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        onTap: () {
          if (!isSelected) {
            Navigator.pushReplacementNamed(context, route);
          } else {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
