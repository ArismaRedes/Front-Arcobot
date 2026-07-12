import 'package:flutter/material.dart';
import 'package:front_arcobot/core/theme/app_theme.dart';
import 'package:front_arcobot/core/theme/design_tokens.dart';
import 'package:front_arcobot/core/widgets/arco_avatar.dart';
import 'package:front_arcobot/features/sessions/domain/report_models.dart';

/// Podio de la clase: premios para incentivar a los niños. Pensado para
/// proyectarse al terminar la sesión.
Future<void> showSessionReportDialog(
  BuildContext context,
  SessionReportStats report, {
  String title = '¡Resultados de la clase!',
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => Theme(
      data: AppTheme.dark,
      child: _SessionReportDialog(report: report, title: title),
    ),
  );
}

class _SessionReportDialog extends StatelessWidget {
  const _SessionReportDialog({required this.report, required this.title});

  final SessionReportStats report;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ArcobotPanelColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: ArcobotPanelColors.border, width: 0.5),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: ArcobotColors.sunYellow,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: ArcobotPanelColors.textOnDark,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: ArcobotPanelColors.subtle,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${report.students} estudiantes · ${report.attempts} intentos '
                  '· ${report.successes} logros '
                  '(${(report.successRate * 100).round()}% de éxito)',
                  style: const TextStyle(
                    color: ArcobotPanelColors.subtle,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 18),
                if (!report.hasAwards)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'Nadie alcanzó a jugar en esta clase.',
                        style: TextStyle(
                          color: ArcobotPanelColors.subtle,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  )
                else ...[
                  if (report.topSolver != null)
                    _AwardTile(
                      award: report.topSolver!,
                      icon: Icons.emoji_events_rounded,
                      color: ArcobotColors.sunYellow,
                      label: 'Campeón de pistas',
                    ),
                  if (report.fastest != null)
                    _AwardTile(
                      award: report.fastest!,
                      icon: Icons.bolt_rounded,
                      color: ArcobotColors.skyBlue,
                      label: 'Rayo veloz',
                    ),
                  if (report.mostPersistent != null)
                    _AwardTile(
                      award: report.mostPersistent!,
                      icon: Icons.fitness_center_rounded,
                      color: ArcobotColors.coral,
                      label: 'Nunca se rinde',
                    ),
                  if (report.mostEfficient != null)
                    _AwardTile(
                      award: report.mostEfficient!,
                      icon: Icons.track_changes_rounded,
                      color: ArcobotColors.guideTurquoise,
                      label: 'Mente maestra',
                    ),
                ],
                if (report.perStudent.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'RESUMEN POR ESTUDIANTE',
                    style: TextStyle(
                      color: ArcobotPanelColors.subtle,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final student in report.perStudent)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          ArcoAvatar(avatarId: student.avatar, size: 26),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              student.alias,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: ArcobotPanelColors.textOnDark,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${student.successes}/${student.attempts}'
                            '${student.bestMs == null ? '' : ' · ${_formatMs(student.bestMs!)}'}',
                            style: const TextStyle(
                              color: ArcobotPanelColors.subtle,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text('Listo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatMs(int ms) {
  final seconds = ms / 1000;
  if (seconds < 60) {
    return '${seconds.toStringAsFixed(1)} s';
  }
  final minutes = seconds ~/ 60;
  final rest = (seconds % 60).round();
  return '$minutes min $rest s';
}

class _AwardTile extends StatelessWidget {
  const _AwardTile({
    required this.award,
    required this.icon,
    required this.color,
    required this.label,
  });

  final ReportAward award;
  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          ArcoAvatar(avatarId: award.avatar, size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                Text(
                  award.alias,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ArcobotPanelColors.textOnDark,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (award.detail != null)
            Text(
              award.detail!,
              style: const TextStyle(
                color: ArcobotPanelColors.subtle,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}
