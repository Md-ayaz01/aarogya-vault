import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/database/local_db.dart';
import 'core/theme/app_theme.dart';
import 'core/network/api_client.dart' show navigatorKey;
import 'core/di/locator.dart';
import 'core/providers/theme_provider.dart';
import 'routes.dart';
import 'firebase_options.dart';

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

  // Initialize Firebase Core safely for phone authentication
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initialization warning: $e");
  }
  runApp(
    const ProviderScope(
      child: AarogyaVaultApp(),
    ),
  );
}

class AarogyaVaultApp extends ConsumerWidget {
  const AarogyaVaultApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Aarogya Vault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      navigatorKey: navigatorKey,  // Enables 401 auto-redirect from API interceptor
      initialRoute: '/splash',
      onGenerateRoute: generateRoute,
    );
  }
}

