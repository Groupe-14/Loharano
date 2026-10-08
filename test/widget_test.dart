import 'package:flutter_test/flutter_test.dart';
import 'package:loharano/app.dart';

void main() {
  testWidgets('HydroCheck Offline shell renders', (WidgetTester tester) async {
    // Injecte la classe racine App() déclarée dans app.dart
    await tester.pumpWidget(const App());

    // Vérifie la présence du texte 'HydrocheckAI' dans l'AppBar
    expect(find.textContaining('HydrocheckAI'), findsOneWidget);
  });
}
