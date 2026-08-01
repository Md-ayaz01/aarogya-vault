import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/database/local_db.dart';
import 'core/theme/app_theme.dart';
import 'core/network/api_client.dart' show navigatorKey;
import 'core/di/locator.dart';
import 'core/providers/theme_provider.dart';
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

  // Initialize Firebase Core safely for phone authentication
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: String.fromEnvironment('FIREBASE_API_KEY', defaultValue: 'AIzaSyDemoKeyForAarogyaVaultWeb'),
          appId: String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '1:1234567890:web:aarogyavaultwebid'),
          messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '1234567890'),
          projectId: String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'aarogya-vault'),
          authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN', defaultValue: 'aarogya-vault.firebaseapp.com'),
          storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: 'aarogya-vault.appspot.com'),
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint("Firebase initialization warning: Firebase may be unavailable in local/test environments. OTP fallback is handled by backend.");
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

