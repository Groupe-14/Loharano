import '../models/risk_level.dart';

class RiskResult {
  const RiskResult({
    required this.level,
    required this.confidence,
    required this.reasons,
    required this.actions,
    this.testType = 'visual',
  });

  final RiskLevel level;
  final double confidence;
  final List<String> reasons;
  final List<GuideAction> actions;
  final String testType;

  bool get isDemo => false;
}
