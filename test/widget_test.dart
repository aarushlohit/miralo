import 'package:flutter_test/flutter_test.dart';
import 'package:miralo/app.dart';

void main() {
  testWidgets('MiraloApp initial splash test', (WidgetTester tester) async {
    await tester.pumpWidget(const MiraloApp());
    await tester.pump();

    // Verify that MIRALO AI branding and tagline are rendered
    expect(find.text('MIRALO AI'), findsWidgets);
    expect(find.text('Your AI. Your Space.'), findsOneWidget);
  });
}
