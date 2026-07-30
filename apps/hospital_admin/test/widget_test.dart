import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_admin/main.dart';

void main() {
  testWidgets('Hospital Admin App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HospitalAdminApp());
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(HospitalAdminApp), findsOneWidget);
  });
}
