import 'package:flutter/material.dart';

class SuperAdminDrawer extends StatelessWidget {
  final String currentRoute;
  const SuperAdminDrawer({super.key, required this.currentRoute});

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
            decoration: const BoxDecoration(color: primaryTeal),
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
                      child: const Icon(Icons.admin_panel_settings_rounded, color: activeColor, size: 28),
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
                          'SUPER ADMIN PORTAL',
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
                _drawerTile(context, 'Platform Dashboard', Icons.dashboard_rounded, '/dashboard'),
                _drawerTile(context, 'Hospital Approvals', Icons.verified_user_rounded, '/hospitals'),
                _drawerTile(context, 'Doctor Verification', Icons.medical_services_rounded, '/doctors'),
                _drawerTile(context, 'Master Patient Registry', Icons.people_alt_rounded, '/patients'),
                _drawerTile(context, 'User Management', Icons.manage_accounts_rounded, '/users'),
                _drawerTile(context, 'AI Control Center', Icons.psychology_rounded, '/ai-control'),
                _drawerTile(context, 'Emergency Surveillance', Icons.emergency_rounded, '/emergency'),
                _drawerTile(context, 'Ayushman PM-JAY', Icons.health_and_safety_rounded, '/ayushman'),
                _drawerTile(context, 'Platform Analytics', Icons.analytics_rounded, '/analytics'),
                _drawerTile(context, 'Executive Reports', Icons.assessment_rounded, '/reports'),
                _drawerTile(context, 'Universal Audit Trail', Icons.history_edu_rounded, '/audit'),
                _drawerTile(context, 'RBAC Matrix', Icons.security_rounded, '/rbac'),
                _drawerTile(context, 'API Keys & Webhooks', Icons.api_rounded, '/api-management'),
                _drawerTile(context, 'Broadcast Alerts', Icons.campaign_rounded, '/notifications'),
                _drawerTile(context, 'Platform Settings', Icons.settings_rounded, '/settings'),
                _drawerTile(context, 'Subscriptions & Billing', Icons.card_membership_rounded, '/subscriptions'),
                const Divider(),
                _drawerTile(context, 'Support Center', Icons.support_agent_rounded, '/support'),
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
                  child: Text('SA', style: TextStyle(color: activeColor, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('System Overseer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('Super Administrator', style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.red),
                  onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
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
