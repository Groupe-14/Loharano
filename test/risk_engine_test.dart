import 'package:flutter_test/flutter_test.dart';
import 'package:loharano/core/models/risk_level.dart';
import 'package:loharano/core/risk/risk_engine.dart';
import 'package:loharano/core/risk/risk_inputs.dart';

void main() {
  const engine = RiskEngine();

  test('sans réponse, le résultat est inconnu', () {
    final result = engine.evaluate(const RiskInputs());
    expect(result.level, RiskLevel.unknown);
    expect(result.actions, contains(GuideAction.boil));
  });

  test(
      'eau de rivière trouble et odorante : risque élevé, filtrer puis bouillir',
      () {
    final result = engine.evaluate(const RiskInputs(
        sourceType: SourceType.river, looksTurbid: true, badSmell: true));
    expect(result.level, RiskLevel.high);
    expect(
        result.actions,
        containsAll(
            [GuideAction.filter, GuideAction.boil, GuideAction.otherSource]));
    expect(
        result.confidence, lessThanOrEqualTo(RiskEngine.visualConfidenceCap));
  });

  test(
      'eau claire de forage : risque faible non garanti, avec consigne de bouillir',
      () {
    final result = engine.evaluate(const RiskInputs(
        sourceType: SourceType.borehole,
        looksTurbid: false,
        badSmell: false,
        cleanContainer: true));
    expect(result.level, RiskLevel.low);
    expect(result.level.label, 'Risque faible (non garanti)');
    expect(result.actions, contains(GuideAction.boil));
    expect(result.reasons.join(' '), isNot(contains('potable')));
  });

  test('pluie et latrine relèvent une eau de puits', () {
    final result = engine.evaluate(const RiskInputs(
        sourceType: SourceType.well,
        looksTurbid: false,
        recentRain: true,
        latrineOrAnimalsNearby: true));
    expect(result.level, RiskLevel.medium);
  });

  test('marque disparue compte comme une eau trouble', () {
    final result = engine.evaluate(
        const RiskInputs(sourceType: SourceType.pump, markVisible: false));
    expect(result.level, RiskLevel.medium);
    expect(result.actions, contains(GuideAction.filter));
  });
}
