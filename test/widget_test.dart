import 'package:flutter_test/flutter_test.dart';
import 'package:loharano/app.dart';

void main() {
  testWidgets('Loharano affiche le dépistage', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    expect(find.textContaining('Loharano'), findsOneWidget);
    expect(find.text('Tester'), findsWidgets);
    expect(find.textContaining('certificat'), findsOneWidget);
    expect(find.text('SAFE'), findsNothing);
  });
}
