import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/database/local_db.dart';
import 'core/theme/app_theme.dart';
import 'core/network/api_client.dart' show navigatorKey;
import 'core/di/locator.dart';
import 'routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Dependency Injection
  setupLocator();
  
  // Initialize local caching database
  await LocalDB.init();

  // Initialize Supabase Safely
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
    } catch (e) {
      debugPrint("Supabase initialization error: $e");
    }
  }

  runApp(const AarogyaVaultDoctorApp());
}

class AarogyaVaultDoctorApp extends StatelessWidget {
  const AarogyaVaultDoctorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final loggedIn = LocalDB.isLoggedIn();

    return MaterialApp(
      title: 'Aarogya Vault Doctor App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      navigatorKey: navigatorKey,  // Enables 401 auto-redirect from API interceptor
      initialRoute: loggedIn ? '/dashboard' : '/login',
      onGenerateRoute: generateRoute,
    );
  }
}
