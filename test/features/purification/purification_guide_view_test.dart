import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loharano/features/purification/purification_guide_view.dart';
import 'package:loharano/features/purification/widgets/step_item_card.dart';
import 'package:loharano/features/purification/widgets/water_status_card.dart';

void main() {
  group('PurificationGuideView Widget Tests', () {
    testWidgets('Affiche la carte de statut au démarrage',
        (WidgetTester tester) async {
      // 1. Charger le widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PurificationGuideView(),
          ),
        ),
      );

      // 2. Vérifier que la carte de statut est présente
      expect(find.byType(WaterStatusCard), findsOneWidget);
      expect(find.text('Eau Saine'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets(
        'Bascule vers les étapes de purification lors du clic sur le bouton',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PurificationGuideView(),
          ),
        ),
      );

      // La carte expose un unique bouton d'action pour ouvrir les étapes.
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle(); // Attendre l'animation / le setState

      // Vérifier que la liste des consignes s'affiche
      expect(find.text('Étapes à suivre'), findsOneWidget);
      expect(find.byType(StepItemCard), findsNWidgets(3));
      expect(find.text('1. Couvrir'), findsOneWidget);
      expect(find.text('Terminer / Nouvel essai'), findsOneWidget);
    });
  });
}
