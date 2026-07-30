import 'package:flutter_test/flutter_test.dart';
import 'package:super_admin/main.dart';

void main() {
  testWidgets('Super Admin App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SuperAdminApp());
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(SuperAdminApp), findsOneWidget);
  });
}
