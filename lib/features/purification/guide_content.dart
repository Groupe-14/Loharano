import 'package:flutter/material.dart';

import '../../core/models/risk_level.dart';
import '../../core/risk/risk_result.dart';

class GuideStepView {
  const GuideStepView(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.speech});

  final IconData icon;
  final String title;
  final String subtitle;
  final String speech;
}

List<GuideStepView> stepsFor(RiskResult? result) {
  final actions =
      result?.actions ?? const [GuideAction.retake, GuideAction.boil];
  final steps = <GuideStepView>[];
  var index = 1;
  for (final action in actions) {
    steps.add(GuideStepView(
      icon: _icon(action),
      title: '$index. ${action.title}',
      subtitle: action.subtitle,
      speech: '${action.title}. ${action.subtitle}',
    ));
    index += 1;
  }
  return steps;
}

IconData _icon(GuideAction action) => switch (action) {
      GuideAction.filter => Icons.grid_view,
      GuideAction.boil => Icons.whatshot,
      GuideAction.coolCovered => Icons.ac_unit,
      GuideAction.coverContainer => Icons.water_drop,
      GuideAction.keepCool => Icons.park_outlined,
      GuideAction.retake => Icons.refresh,
      GuideAction.otherSource => Icons.wrong_location_outlined,
    };
