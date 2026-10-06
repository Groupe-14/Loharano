import '../models/risk_level.dart';

class RiskInputs {
  const RiskInputs({
    this.sourceType = SourceType.unknown,
    this.looksTurbid,
    this.badSmell,
    this.recentRain,
    this.latrineOrAnimalsNearby,
    this.cleanContainer,
    this.markVisible,
  });

  final SourceType sourceType;
  final bool? looksTurbid;
  final bool? badSmell;
  final bool? recentRain;
  final bool? latrineOrAnimalsNearby;
  final bool? cleanContainer;

  /// null = photo non utilisée. false = la marque imprimée a disparu.
  final bool? markVisible;
}
