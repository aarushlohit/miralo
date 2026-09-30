import 'package:flutter_test/flutter_test.dart';
import 'package:longcat/app.dart';
import 'package:longcat/providers/vault_provider.dart';

void main() {
  testWidgets('LongcatApp initial splash test', (WidgetTester tester) async {
    await tester.pumpWidget(LongcatApp(vault: VaultProvider()));
    await tester.pump();

    // Verify that LONGCAT AI branding and tagline are rendered
    expect(find.text('LONGCAT AI'), findsWidgets);
    expect(find.text('Your AI. Your Space.'), findsOneWidget);
  });
}
