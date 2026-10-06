import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loharano/core/models/risk_level.dart';
import 'package:loharano/core/risk/risk_result.dart';
import 'package:loharano/features/purification/purification_guide_view.dart';
import 'package:loharano/features/purification/widgets/step_item_card.dart';
import 'package:loharano/features/purification/widgets/water_status_card.dart';

void main() {
  testWidgets('sans résultat, le guide dit qu’il ne sait pas', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PurificationGuideView())));
    expect(find.byType(WaterStatusCard), findsOneWidget);
    expect(find.text('Inconnu'), findsOneWidget);
    expect(find.textContaining('potable'), findsNothing);
    expect(find.textContaining('Eau saine'), findsNothing);
  });

  testWidgets('un risque moyen ouvre les actions, dont filtrer',
      (tester) async {
    const result = RiskResult(
      level: RiskLevel.medium,
      confidence: 0.5,
      reasons: ['Eau trouble'],
      actions: [GuideAction.filter, GuideAction.boil],
    );
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: PurificationGuideView(result: result))));
    await tester.tap(find.text('Voir les actions'));
    await tester.pumpAndSettle();
    expect(find.text('Actions'), findsOneWidget);
    expect(find.byType(StepItemCard), findsNWidgets(2));
    expect(find.textContaining('Filtrer'), findsOneWidget);
    expect(find.text('Terminer'), findsOneWidget);
  });
}
