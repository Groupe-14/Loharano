import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/water_diagnostic.dart';

/// Tableau de bord des résultats d'analyse : pH, turbidité et chlore.
///
/// Remplace [TurbidityGaugeWidget] pour un affichage riche multi-paramètres.
class ResultDashboardWidget extends StatefulWidget {
  const ResultDashboardWidget({super.key, required this.diagnostic});

  final WaterDiagnostic diagnostic;

  @override
  State<ResultDashboardWidget> createState() => _ResultDashboardWidgetState();
}

class _ResultDashboardWidgetState extends State<ResultDashboardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _progress = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    _anim.forward();
  }

  @override
  void didUpdateWidget(ResultDashboardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.diagnostic != widget.diagnostic) {
      _anim.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diag = widget.diagnostic;
    final statusColor = _colorFor(diag.status);

    return AnimatedBuilder(
      animation: _progress,
      builder: (context, _) {
        return Card(
          margin: EdgeInsets.zero,
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── En-tête statut ────────────────────────────────────────
                _StatusBanner(diagnostic: diag, statusColor: statusColor),
                const SizedBox(height: 20),

                // ── Turbidité ─────────────────────────────────────────────
                _ParameterRow(
                  label: 'Turbidité',
                  value:
                      '${(diag.turbidityScore * _progress.value * 100).toStringAsFixed(1)} NTU',
                  progressValue: diag.turbidityScore * _progress.value,
                  color: statusColor,
                  icon: Icons.water,
                  hint: _turbidityHint(diag.turbidityScore),
                ),
                const SizedBox(height: 14),

                // ── pH ────────────────────────────────────────────────────
                if (diag.phValue != null) ...[
                  _ParameterRow(
                    label: 'pH estimé',
                    value: (diag.phValue! * _progress.value)
                        .toStringAsFixed(1),
                    progressValue:
                        ((diag.phValue! * _progress.value) / 14.0).clamp(
                      0.0,
                      1.0,
                    ),
                    color: _phColor(diag.phValue!),
                    icon: Icons.science,
                    hint: _phHint(diag.phValue!),
                    optimalMin: 6.5 / 14.0,
                    optimalMax: 8.5 / 14.0,
                  ),
                  const SizedBox(height: 14),
                ],

                // ── Chlore ────────────────────────────────────────────────
                if (diag.chlorineLevel != null) ...[
                  _ParameterRow(
                    label: 'Chlore / Contaminants',
                    value:
                        '${(diag.chlorineLevel! * _progress.value).toStringAsFixed(2)} mg/L',
                    progressValue:
                        ((diag.chlorineLevel! * _progress.value) / 10.0)
                            .clamp(0.0, 1.0),
                    color: _chlorineColor(diag.chlorineLevel!),
                    icon: Icons.colorize,
                    hint: _chlorineHint(diag.chlorineLevel!),
                    optimalMin: 0.02,
                    optimalMax: 0.20,
                  ),
                  const SizedBox(height: 14),
                ],

                // ── Confiance ─────────────────────────────────────────────
                _ConfidenceChip(confidence: diag.confidence),
                const SizedBox(height: 16),

                // ── Recommandations ───────────────────────────────────────
                ...diag.recommendations.map(
                  (rec) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.arrow_right,
                            color: statusColor, size: 18),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(rec,
                              style: const TextStyle(
                                  fontSize: 13, height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Couleurs / Hints ───────────────────────────────────────────────────

  Color _colorFor(WaterDiagnosticStatus s) => switch (s) {
        WaterDiagnosticStatus.safe => AppColors.safe,
        WaterDiagnosticStatus.warning => AppColors.warning,
        WaterDiagnosticStatus.danger => AppColors.danger,
      };

  Color _phColor(double ph) {
    if (ph < 6.5 || ph > 8.5) return AppColors.danger;
    if (ph < 6.8 || ph > 8.2) return AppColors.warning;
    return AppColors.safe;
  }

  Color _chlorineColor(double cl) {
    if (cl > 4.0) return AppColors.danger;
    if (cl > 2.0 || cl < 0.1) return AppColors.warning;
    return AppColors.safe;
  }

  String _turbidityHint(double score) {
    if (score < 0.30) return 'Eau claire (< 30 NTU)';
    if (score < 0.65) return 'Eau légèrement trouble (30–65 NTU)';
    return 'Eau très trouble (> 65 NTU)';
  }

  String _phHint(double ph) {
    if (ph < 6.5) return 'Eau acide — risque de corrosion';
    if (ph > 8.5) return 'Eau basique — traitement conseillé';
    return 'pH dans la plage optimale (6.5–8.5)';
  }

  String _chlorineHint(double cl) {
    if (cl < 0.1) return 'Pas de désinfectant résiduel détecté';
    if (cl > 4.0) return 'Chlore excessif — dangereux';
    if (cl > 2.0) return 'Taux de chlore élevé';
    return 'Chlore résiduel normal (0.2–2.0 mg/L)';
  }
}

// ─── Sous-widgets ───────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  const _StatusBanner(
      {required this.diagnostic, required this.statusColor});
  final WaterDiagnostic diagnostic;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: statusColor.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(_iconFor(diagnostic.status), color: statusColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Eau ${diagnostic.status.label}',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                Text(
                  _subtitle(diagnostic.status),
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(WaterDiagnosticStatus s) => switch (s) {
        WaterDiagnosticStatus.safe => Icons.check_circle,
        WaterDiagnosticStatus.warning => Icons.warning_amber_rounded,
        WaterDiagnosticStatus.danger => Icons.dangerous,
      };

  String _subtitle(WaterDiagnosticStatus s) => switch (s) {
        WaterDiagnosticStatus.safe => 'Potable — qualité satisfaisante',
        WaterDiagnosticStatus.warning =>
          'Inquiétant — purification recommandée',
        WaterDiagnosticStatus.danger =>
          'Dangereux — ne pas consommer',
      };
}

class _ParameterRow extends StatelessWidget {
  const _ParameterRow({
    required this.label,
    required this.value,
    required this.progressValue,
    required this.color,
    required this.icon,
    required this.hint,
    this.optimalMin,
    this.optimalMax,
  });

  final String label;
  final String value;
  final double progressValue;
  final Color color;
  final IconData icon;
  final String hint;
  final double? optimalMin;
  final double? optimalMax;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressValue.clamp(0.0, 1.0),
                color: color,
                backgroundColor: color.withAlpha(30),
                minHeight: 8,
              ),
            ),
            // Plage optimale
            if (optimalMin != null && optimalMax != null)
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (_, constraints) => Stack(
                    children: [
                      Positioned(
                        left: constraints.maxWidth * optimalMin!,
                        width: constraints.maxWidth *
                            (optimalMax! - optimalMin!),
                        top: 0,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.green.withAlpha(50),
                            border: const Border(
                              left: BorderSide(
                                  color: Colors.green, width: 1.5),
                              right: BorderSide(
                                  color: Colors.green, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(hint,
            style: const TextStyle(fontSize: 11, color: Colors.black45)),
      ],
    );
  }
}

class _ConfidenceChip extends StatelessWidget {
  const _ConfidenceChip({required this.confidence});
  final double confidence;

  @override
  Widget build(BuildContext context) {
    final percent = (confidence * 100).round();
    return Row(
      children: [
        const Icon(Icons.analytics_outlined, size: 14, color: Colors.black45),
        const SizedBox(width: 4),
        Text(
          'Confiance de l\'analyse : $percent %',
          style: const TextStyle(fontSize: 12, color: Colors.black45),
        ),
      ],
    );
  }
}
