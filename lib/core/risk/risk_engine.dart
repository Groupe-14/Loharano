import '../models/risk_level.dart';
import 'risk_inputs.dart';
import 'risk_result.dart';

class RiskEngine {
  const RiskEngine();

  static const visualConfidenceCap = 0.55;

  RiskResult evaluate(RiskInputs input) {
    if (!_answered(input)) {
      return const RiskResult(
        level: RiskLevel.unknown,
        confidence: 0,
        reasons: ['Pas assez d’informations pour dépister.'],
        actions: [GuideAction.retake, GuideAction.boil],
      );
    }

    var level = RiskLevel.low;
    var confidence = 0.35;
    final reasons = <String>[];
    final actions = <GuideAction>{};
    final turbid = input.looksTurbid == true || input.markVisible == false;

    void atLeast(RiskLevel floor) {
      if (floor.rank > level.rank) level = floor;
    }

    if (input.sourceType.isSurface) {
      atLeast(RiskLevel.medium);
      confidence = 0.45;
      reasons.add(
          'Eau de surface : elle doit être traitée avant toute consommation.');
      actions.add(GuideAction.boil);
    }

    if (turbid) {
      atLeast(RiskLevel.medium);
      if (confidence < 0.5) confidence = 0.5;
      reasons.add(
          'Eau trouble : filtrez avant de désinfecter. Le trouble n’est pas à lui seul une preuve de pollution chimique.');
      actions.addAll([GuideAction.filter, GuideAction.boil]);
    }

    if (input.badSmell == true) {
      atLeast(RiskLevel.high);
      reasons.add('Odeur anormale.');
      actions.addAll([GuideAction.boil, GuideAction.otherSource]);
    }

    final rain = input.recentRain == true;
    final latrine = input.latrineOrAnimalsNearby == true;
    if (rain && latrine) {
      atLeast(level == RiskLevel.low ? RiskLevel.medium : RiskLevel.high);
      reasons.add('Pluie récente et latrine ou animaux à proximité.');
      actions.add(GuideAction.boil);
    } else if (rain) {
      reasons.add(
          'Pluie récente : l’eau de ruissellement a pu entrer dans la source.');
      atLeast(RiskLevel.medium);
      actions.add(GuideAction.boil);
    } else if (latrine) {
      reasons.add('Latrine ou animaux proches de la source.');
      atLeast(RiskLevel.medium);
      actions.add(GuideAction.boil);
    }

    if (input.cleanContainer == false) {
      reasons.add(
          'Récipient sale : l’eau peut être recontaminée après le traitement.');
      actions.add(GuideAction.coverContainer);
      atLeast(RiskLevel.medium);
    }

    if (input.markVisible == true && input.looksTurbid != true) {
      reasons.add(
          'La marque sous le gobelet reste visible. Cela parle du trouble, pas des microbes.');
    } else if (input.looksTurbid == false && !turbid) {
      reasons.add(
          'L’eau paraît claire. Les microbes, les pesticides et la plupart des métaux restent invisibles.');
    }

    if (level == RiskLevel.low) {
      reasons.add('Aucun signe visible fort. Ce n’est pas une garantie.');
      actions.addAll(
          [GuideAction.coverContainer, GuideAction.keepCool, GuideAction.boil]);
      confidence = 0.3;
    } else {
      actions.add(GuideAction.coolCovered);
    }

    if (confidence > visualConfidenceCap) confidence = visualConfidenceCap;
    return RiskResult(
        level: level,
        confidence: confidence,
        reasons: reasons,
        actions: actions.toList());
  }

  bool _answered(RiskInputs input) {
    return input.sourceType != SourceType.unknown ||
        input.looksTurbid != null ||
        input.badSmell != null ||
        input.recentRain != null ||
        input.latrineOrAnimalsNearby != null ||
        input.cleanContainer != null ||
        input.markVisible != null;
  }
}
