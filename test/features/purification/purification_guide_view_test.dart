import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loharano/core/models/water_test_model.dart';
import 'package:loharano/features/purification/purification_guide_view.dart';
import 'package:loharano/features/purification/widgets/step_item_card.dart';
import 'package:loharano/features/purification/widgets/water_status_card.dart';

void main() {
  final dummyWaterTest = WaterTestModel(
    id: 1,
    turbidityScore: 0.0,
    status: WaterTestStatus.safe,
    timestamp: DateTime.now(),
  );

  group('PurificationGuideView Widget Tests', () {
    testWidgets('Affiche le message d’absence d’analyse si waterTest est null',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PurificationGuideView(),
          ),
        ),
      );

      expect(find.text('Aucune analyse en cours'), findsOneWidget);
    });

    testWidgets('Affiche la carte de statut lorsqu’un test d’eau est fourni',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PurificationGuideView(waterTest: dummyWaterTest),
          ),
        ),
      );

      expect(find.byType(WaterStatusCard), findsOneWidget);
      expect(find.text('Eau Saine'), findsOneWidget);
    });

    testWidgets(
        'Bascule vers les étapes de purification lors du clic sur le bouton de la carte',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PurificationGuideView(waterTest: dummyWaterTest),
          ),
        ),
      );

      // Sur WaterStatus.safe, le bouton porte le texte 'Conseils de conservation'
      await tester.tap(find.text('Conseils de conservation'));
      await tester.pumpAndSettle();

      // Vérifications de l'affichage des étapes
      expect(find.text('Étapes à suivre'), findsOneWidget);
      expect(find.byType(StepItemCard), findsNWidgets(3));
      expect(find.text('1. Couvrir'), findsOneWidget);
      expect(find.text('Terminer / Nouvel essai'), findsOneWidget);
    });
  });
}
