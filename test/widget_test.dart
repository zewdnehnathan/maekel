import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maekel/app/maekel_app.dart';

void main() {
  testWidgets('Maekel shows phone auth gate', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaekelApp()));
    // Backdrop uses a repeating animation — avoid pumpAndSettle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Maekel'), findsOneWidget);
    expect(find.text('Sign in with phone'), findsOneWidget);
  });
}
