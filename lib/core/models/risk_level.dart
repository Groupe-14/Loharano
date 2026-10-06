enum RiskLevel {
  low,
  medium,
  high,
  unknown;

  static RiskLevel parse(String raw) => RiskLevel.values.byName(raw);

  String get label => switch (this) {
        RiskLevel.low => 'Risque faible (non garanti)',
        RiskLevel.medium => 'Risque moyen',
        RiskLevel.high => 'Risque élevé',
        RiskLevel.unknown => 'Inconnu',
      };

  int get rank => switch (this) {
        RiskLevel.unknown => 0,
        RiskLevel.low => 1,
        RiskLevel.medium => 2,
        RiskLevel.high => 3,
      };
}

enum SourceType {
  pump,
  well,
  borehole,
  tap,
  river,
  lake,
  rain,
  other,
  unknown;

  static SourceType parse(String? raw) =>
      raw == null ? SourceType.unknown : SourceType.values.byName(raw);

  String get label => switch (this) {
        SourceType.pump => 'Pompe',
        SourceType.well => 'Puits',
        SourceType.borehole => 'Forage',
        SourceType.tap => 'Robinet',
        SourceType.river => 'Rivière',
        SourceType.lake => 'Lac',
        SourceType.rain => 'Eau de pluie',
        SourceType.other => 'Autre',
        SourceType.unknown => 'Je ne sais pas',
      };

  bool get isSurface => this == SourceType.river || this == SourceType.lake;
}

enum GuideAction {
  filter,
  boil,
  coolCovered,
  coverContainer,
  keepCool,
  retake,
  otherSource;

  static GuideAction parse(String raw) => GuideAction.values.byName(raw);

  String get title => switch (this) {
        GuideAction.filter => 'Filtrer',
        GuideAction.boil => 'Faire bouillir',
        GuideAction.coolCovered => 'Refroidir à couvert',
        GuideAction.coverContainer => 'Couvrir le récipient',
        GuideAction.keepCool => 'Garder au frais',
        GuideAction.retake => 'Refaire le dépistage',
        GuideAction.otherSource => 'Chercher une autre source',
      };

  String get subtitle => switch (this) {
        GuideAction.filter =>
          'Bouteille coupée, sable, gravier, tissu propre. Versez lentement, deux fois.',
        GuideAction.boil =>
          'Feu vif jusqu’à gros bouillons, puis 10 minutes complètes.',
        GuideAction.coolCovered =>
          'Couvrez et laissez refroidir. Ne transvasez pas dans un récipient sale.',
        GuideAction.coverContainer =>
          'Gardez le bidon fermé pour éviter une nouvelle contamination.',
        GuideAction.keepCool => 'À l’ombre, loin du soleil.',
        GuideAction.retake =>
          'La photo ou les réponses ne suffisent pas pour conclure.',
        GuideAction.otherSource =>
          'Si l’odeur ou le lieu inquiète, ne comptez pas sur ce point d’eau.',
      };
}
