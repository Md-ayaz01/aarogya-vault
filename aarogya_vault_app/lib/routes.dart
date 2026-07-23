// lib/routes.dart
import 'package:flutter/material.dart';
import 'package:aarogya_vault_app/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:aarogya_vault_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:aarogya_vault_app/features/reports/presentation/screens/reports_screen.dart';
import 'package:aarogya_vault_app/features/emergency_qr/presentation/screens/emergency_qr_screen.dart';
import 'package:aarogya_vault_app/features/ai_assistant/presentation/screens/ai_assistant_screen.dart';
import 'package:aarogya_vault_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:aarogya_vault_app/features/splash_onboarding/presentation/screens/splash_screen.dart';
import 'package:aarogya_vault_app/features/ayushman/presentation/screens/ayushman_screen.dart';
import 'package:aarogya_vault_app/features/medical_history/presentation/screens/medical_history_screen.dart';
import 'package:aarogya_vault_app/features/ayushman/presentation/screens/find_specialists_screen.dart';
import 'package:aarogya_vault_app/features/reminders/presentation/screens/medicine_reminders_screen.dart';
import 'package:aarogya_vault_app/features/prescriptions/presentation/screens/prescriptions_list_screen.dart';
import 'package:aarogya_vault_app/features/dashboard/presentation/screens/search_screen.dart';

Route<dynamic>? generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/dashboard':
      return MaterialPageRoute(builder: (_) => const DashboardScreen());
    case '/profile':
      return MaterialPageRoute(builder: (_) => const ProfileScreen());
    case '/reports':
      return MaterialPageRoute(builder: (_) => const ReportsScreen());
    case '/emergency_qr':
      return MaterialPageRoute(builder: (_) => const EmergencyQRScreen());
    case '/ai_assistant':
      return MaterialPageRoute(builder: (_) => const AiAssistantScreen());
    case '/settings':
      return MaterialPageRoute(builder: (_) => const SettingsScreen());
    case '/splash':
      return MaterialPageRoute(builder: (_) => const SplashScreen());
    case '/ayushman':
      return MaterialPageRoute(builder: (_) => const AyushmanScreen());
    case '/medical_history':
      return MaterialPageRoute(builder: (_) => const MedicalHistoryScreen());
    case '/find_specialists':
      return MaterialPageRoute(builder: (_) => const FindSpecialistsScreen());
    case '/reminders':
      return MaterialPageRoute(builder: (_) => const MedicineRemindersScreen());
    case '/prescriptions':
      return MaterialPageRoute(builder: (_) => const PrescriptionsListScreen());
    case '/search':
      return MaterialPageRoute(builder: (_) => const SearchScreen());
    default:
      return MaterialPageRoute(builder: (_) => const SplashScreen());
  }
}
