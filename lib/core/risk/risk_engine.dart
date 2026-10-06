import '../models/risk_level.dart';
import 'risk_inputs.dart';
import 'risk_result.dart';

/// Règles de dépistage visuel. Ce n'est pas un avis de potabilité.
/// Les seuils chiffrés d'un laboratoire ne sont pas ici : il n'y a pas de réactif.
class RiskEngine {
  const RiskEngine();

  static const visualConfidenceCap = 0.55;

  RiskResult evaluate(RiskInputs input) {
    final answered = input.looksTurbid != null ||
        input.badSmell != null ||
        input.recentRain != null ||
        input.latrineOrAnimalsNearby != null ||
        input.cleanContainer != null ||
        input.markVisible != null ||
        input.sourceType != SourceType.unknown;

    if (!answered) {
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
    final surface = input.sourceType == SourceType.river ||
        input.sourceType == SourceType.lake;

    if (surface) {
      level = _raise(level, RiskLevel.medium);
      confidence = 0.45;
      reasons.add(
          'Eau de surface : elle doit être traitée avant toute consommation.');
      actions.add(GuideAction.boil);
    }

    if (turbid) {
      level = _raise(level, RiskLevel.medium);
      confidence = confidence < 0.5 ? 0.5 : confidence;
      reasons.add(
          'Eau trouble : filtrez avant de désinfecter. Le trouble n’est pas à lui seul une preuve de pollution chimique.');
      actions
        ..add(GuideAction.filter)
        ..add(GuideAction.boil);
    }

    if (input.badSmell == true) {
      level = _raise(level, RiskLevel.high);
      reasons.add('Odeur anormale.');
      actions
        ..add(GuideAction.boil)
        ..add(GuideAction.otherSource);
    }

    if (input.recentRain == true && input.latrineOrAnimalsNearby == true) {
      level = _raise(
          level, level == RiskLevel.low ? RiskLevel.medium : RiskLevel.high);
      reasons.add('Pluie récente et latrine ou animaux à proximité.');
      actions.add(GuideAction.boil);
    } else if (input.recentRain == true) {
      reasons.add(
          'Pluie récente : l’eau de ruissellement a pu entrer dans la source.');
      if (level == RiskLevel.low) level = RiskLevel.medium;
      actions.add(GuideAction.boil);
    } else if (input.latrineOrAnimalsNearby == true) {
      reasons.add('Latrine ou animaux proches de la source.');
      if (level == RiskLevel.low) level = RiskLevel.medium;
      actions.add(GuideAction.boil);
    }

    if (input.cleanContainer == false) {
      reasons.add(
          'Récipient sale : l’eau peut être recontaminée après le traitement.');
      actions.add(GuideAction.coverContainer);
      if (level == RiskLevel.low) level = RiskLevel.medium;
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
      actions: actions.toList(),
    );
  }

  RiskLevel _raise(RiskLevel current, RiskLevel floor) =>
      current.rank >= floor.rank ? current : floor;
}
