import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asisten_keuangan/main.dart';

void main() {
  testWidgets('Smoke test render app dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AsistenKeuanganApp(),
      ),
    );

    expect(find.text('Asisten Keuangan'), findsOneWidget);
  });
}
