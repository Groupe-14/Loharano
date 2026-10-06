import 'package:flutter/material.dart';
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

  testWidgets('le dépistage tient sur un téléphone', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const App());
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Purifier'));
    await tester.pump();
    expect(find.text('Inconnu'), findsOneWidget);
    expect(find.text('Voir les actions'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Historique'));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Carte'));
    await tester.pump();
    expect(find.textContaining('dépistages sur ce téléphone'), findsOneWidget);
    expect(find.text('Envoyer'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Scanner'));
    await tester.pump();
    expect(find.text('Cadrez le QR du point d’eau'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('le résultat ouvre les actions sans enregistrer', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const App());
    await tester.pump();

    await tester.tap(find.text('Forage'));
    await tester.pump();
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.text('Non').hitTestable());
      await tester.pump();
    }
    await tester.tap(find.text('Continuer sans photo'));
    await tester.pump();
    await tester.tap(find.text('Voir les actions').hitTestable());
    await tester.pump();

    expect(find.text('Actions'), findsOneWidget);
    expect(find.textContaining('Couvrir'), findsOneWidget);
    expect(find.textContaining('Loharano · Purifier'), findsOneWidget);
  });
}
