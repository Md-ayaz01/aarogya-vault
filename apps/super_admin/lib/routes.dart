import 'package:flutter/material.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/hospitals/presentation/screens/hospital_approval_screen.dart';
import 'features/doctors/presentation/screens/doctor_verification_screen.dart';
import 'features/patients/presentation/screens/patient_master_screen.dart';
import 'features/users/presentation/screens/user_management_screen.dart';
import 'features/ai_control/presentation/screens/ai_control_screen.dart';
import 'features/emergency/presentation/screens/emergency_audit_screen.dart';
import 'features/ayushman/presentation/screens/ayushman_management_screen.dart';
import 'features/analytics/presentation/screens/platform_analytics_screen.dart';
import 'features/reports/presentation/screens/platform_reports_screen.dart';
import 'features/audit/presentation/screens/audit_trail_screen.dart';
import 'features/rbac/presentation/screens/rbac_matrix_screen.dart';
import 'features/api_management/presentation/screens/api_management_screen.dart';
import 'features/notifications/presentation/screens/broadcast_notifications_screen.dart';
import 'features/settings/presentation/screens/platform_settings_screen.dart';
import 'features/subscriptions/presentation/screens/subscriptions_screen.dart';
import 'features/support/presentation/screens/support_center_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String hospitals = '/hospitals';
  static const String doctors = '/doctors';
  static const String patients = '/patients';
  static const String users = '/users';
  static const String aiControl = '/ai-control';
  static const String emergency = '/emergency';
  static const String ayushman = '/ayushman';
  static const String analytics = '/analytics';
  static const String reports = '/reports';
  static const String audit = '/audit';
  static const String rbac = '/rbac';
  static const String apiManagement = '/api-management';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String subscriptions = '/subscriptions';
  static const String support = '/support';

  static Map<String, WidgetBuilder> get routes => {
    login: (context) => const SuperAdminLoginScreen(),
    dashboard: (context) => const SuperAdminDashboardScreen(),
    hospitals: (context) => const HospitalApprovalScreen(),
    doctors: (context) => const DoctorVerificationScreen(),
    patients: (context) => const PatientMasterScreen(),
    users: (context) => const UserManagementScreen(),
    aiControl: (context) => const AIControlScreen(),
    emergency: (context) => const EmergencyAuditScreen(),
    ayushman: (context) => const AyushmanManagementScreen(),
    analytics: (context) => const PlatformAnalyticsScreen(),
    reports: (context) => const PlatformReportsScreen(),
    audit: (context) => const AuditTrailScreen(),
    rbac: (context) => const RBACMatrixScreen(),
    apiManagement: (context) => const APIManagementScreen(),
    notifications: (context) => const BroadcastNotificationsScreen(),
    settings: (context) => const PlatformSettingsScreen(),
    subscriptions: (context) => const SubscriptionsScreen(),
    support: (context) => const SupportCenterScreen(),
  };
}
