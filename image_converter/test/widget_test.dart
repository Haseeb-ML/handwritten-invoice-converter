import 'package:flutter_test/flutter_test.dart';
import 'package:image_converter/main.dart';

void main() {
  testWidgets('App dashboard smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ScanInvoiceApp());

    // Verify that our dashboard screen loaded successfully.
    expect(find.text('Select Invoice Source'), findsOneWidget);
    expect(find.text('Try with Demo Samples'), findsOneWidget);
  });
}
