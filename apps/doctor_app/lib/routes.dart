import 'package:flutter/material.dart';

import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/otp_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/search/presentation/screens/search_screen.dart';
import 'features/profile/presentation/screens/patient_profile_screen.dart';
import 'features/profile/presentation/screens/patient_timeline_screen.dart';
import 'features/profile/presentation/screens/patient_reports_screen.dart';
import 'features/prescription/presentation/screens/prescription_create_screen.dart';
import 'features/copilot/presentation/screens/ai_copilot_screen.dart';
import 'features/qr/presentation/screens/qr_scanner_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'features/appointments/presentation/screens/appointments_screen.dart';
import 'features/notifications/presentation/screens/notifications_screen.dart';
import 'features/profile/presentation/screens/doctor_profile_screen.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  final args = settings.arguments as Map<String, dynamic>?;

  switch (settings.name) {
    case '/splash':
      return MaterialPageRoute(builder: (_) => const SplashScreen());
    case '/login':
      return MaterialPageRoute(builder: (_) => const LoginScreen());
    case '/otp':
      final phone = args?['phone'] as String? ?? '';
      final verificationId = args?['verificationId'] as String?;
      return MaterialPageRoute(builder: (_) => OTPScreen(phone: phone, verificationId: verificationId));
    case '/dashboard':
      return MaterialPageRoute(builder: (_) => const DashboardScreen());
    case '/search':
      return MaterialPageRoute(builder: (_) => const SearchScreen());
    case '/patient-profile':
      final patientId = args?['patientId'] as int? ?? 0;
      return MaterialPageRoute(builder: (_) => PatientProfileScreen(patientId: patientId));
    case '/timeline':
      final patientId = args?['patientId'] as int? ?? 0;
      return MaterialPageRoute(builder: (_) => PatientTimelineScreen(patientId: patientId));
    case '/reports':
      final patientId = args?['patientId'] as int? ?? 0;
      return MaterialPageRoute(builder: (_) => PatientReportsScreen(patientId: patientId));
    case '/prescription-create':
      final patientId = args?['patientId'] as int? ?? 0;
      final patientName = args?['patientName'] as String? ?? 'Patient';
      return MaterialPageRoute(
        builder: (_) => PrescriptionCreateScreen(patientId: patientId, patientName: patientName),
      );
    case '/ai-copilot':
      final patientId = args?['patientId'] as int? ?? 0;
      return MaterialPageRoute(builder: (_) => AICopilotScreen(patientId: patientId));
    case '/qr-scan':
    case '/qr-scanner':
      return MaterialPageRoute(builder: (_) => const QRScannerScreen());
    case '/settings':
      return MaterialPageRoute(builder: (_) => const SettingsScreen());
    case '/profile':
      return MaterialPageRoute(builder: (_) => const DoctorProfileScreen());
    case '/notifications':
      return MaterialPageRoute(builder: (_) => const NotificationsScreen());
    case '/appointments':
      return MaterialPageRoute(builder: (_) => const AppointmentsScreen());
    default:
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Center(
            child: Text('No route defined for ${settings.name}'),
          ),
        ),
      );
  }
}
