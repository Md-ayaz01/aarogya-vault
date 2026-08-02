import 'package:flutter/material.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/patients/presentation/screens/patient_management_screen.dart';
import 'features/doctors/presentation/screens/doctor_management_screen.dart';
import 'features/departments/presentation/screens/department_management_screen.dart';
import 'features/admissions/presentation/screens/admissions_screen.dart';
import 'features/beds/presentation/screens/bed_allocation_screen.dart';
import 'features/appointments/presentation/screens/appointments_screen.dart';
import 'features/laboratory/presentation/screens/laboratory_screen.dart';
import 'features/radiology/presentation/screens/radiology_screen.dart';
import 'features/pharmacy/presentation/screens/pharmacy_screen.dart';
import 'features/emergency/presentation/screens/emergency_screen.dart';
import 'features/analytics/presentation/screens/ai_analytics_screen.dart';
import 'features/reports/presentation/screens/reports_screen.dart';
import 'features/notifications/presentation/screens/notifications_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> get routes {
    return {
      '/dashboard': (context) => const HospitalDashboardScreen(),
      '/patients': (context) => const PatientManagementScreen(),
      '/doctors': (context) => const DoctorManagementScreen(),
      '/departments': (context) => const DepartmentManagementScreen(),
      '/admissions': (context) => const AdmissionsScreen(),
      '/beds': (context) => const BedAllocationScreen(),
      '/appointments': (context) => const AppointmentsScreen(),
      '/laboratory': (context) => const LaboratoryScreen(),
      '/radiology': (context) => const RadiologyScreen(),
      '/pharmacy': (context) => const PharmacyScreen(),
      '/emergency': (context) => const EmergencyScreen(),
      '/analytics': (context) => const AIAnalyticsScreen(),
      '/reports': (context) => const ReportsScreen(),
      '/notifications': (context) => const NotificationsScreen(),
      '/settings': (context) => const SettingsScreen(),
      '/login': (context) => const HospitalLoginScreen(),
    };
  }
}
