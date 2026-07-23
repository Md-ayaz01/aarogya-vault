import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:aarogya_vault_app/features/splash_onboarding/presentation/screens/splash_screen.dart';

void main() {
  // Setup isolated temporary Hive boxes for widget testing
  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
    await Hive.openBox('auth_box');
    await Hive.openBox('cache_box');
  });

  testWidgets('Splash Screen renders brand title', (WidgetTester tester) async {
    // Configure standard smartphone screen size (600x1200 logical points) to prevent test-only landscape orientation constraints overflows
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SplashScreen(),
        ),
      ),
    );

    // Verify "Aarogya Vault" logo title is displayed (allowing for the newline in the title)
    expect(find.text('Aarogya\nVault'), findsOneWidget);
    
    // Verify tagline message is loaded (which is split in the UI widgets)
    expect(find.text('Always With You.'), findsOneWidget);

    // Settle the navigation timer so the test finishes cleanly
    await tester.pump(const Duration(seconds: 3));
  });
}
