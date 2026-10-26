import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../order_timeline_provider.dart';

List<GanttStage> ganttStagesFromTimeline(
    List<OrderTimelineEvent> events, DateTime now) {
  final stages = <GanttStage>[];
  for (var i = 0; i < events.length; i++) {
    final event = events[i];
    final nextStart = i + 1 < events.length ? events[i + 1].createdAt : null;
    stages.add(GanttStage(
      label: event.statusLabel,
      color: _colorForStatus(event.status),
      start: event.createdAt,
      end: nextStart,
    ));
  }
  return stages;
}

Color _colorForStatus(String status) {
  switch (status) {
    case 'pending':
      return AppColors.statusPending;
    case 'confirmed':
      return AppColors.statusConfirmed;
    case 'preparing':
      return AppColors.statusPreparing;
    case 'ready':
      return AppColors.statusReady;
    case 'picked_up':
      return AppColors.statusDelivering;
    case 'delivered':
      return AppColors.statusDelivered;
    case 'cancelled':
      return AppColors.statusCancelled;
    default:
      return AppColors.statusCancelled;
  }
}

/// One colored stage within a Gantt row (e.g.
class GanttStage {
  final String label;
  final Color color;
  final DateTime start;

  final DateTime? end;

  const GanttStage({
    required this.label,
    required this.color,
    required this.start,
    this.end,
  });
}

/// One row of the chart — typically one order, one rider, or one job.
class GanttRow {
  final String label;
  final String? subtitle;
  final List<GanttStage> stages;
  final VoidCallback? onTap;

  const GanttRow({
    required this.label,
    this.subtitle,
    required this.stages,
    this.onTap,
  });
}

class AppGanttChart extends StatelessWidget {
  final List<GanttRow> rows;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final double labelWidth;
  final double rowHeight;

  const AppGanttChart({
    super.key,
    required this.rows,
    required this.rangeStart,
    required this.rangeEnd,
    this.labelWidth = 96,
    this.rowHeight = 36,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final totalMs =
        rangeEnd.difference(rangeStart).inMilliseconds.clamp(1, 1 << 52);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: InkWell(
              onTap: row.onTap,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: Row(
                children: [
                  SizedBox(
                    width: labelWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(row.label,
                            style: AppTypography.labelSmall
                                .copyWith(color: p.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        if (row.subtitle != null)
                          Text(row.subtitle!,
                              style: AppTypography.bodySmall.copyWith(
                                  color: p.textSecondary, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        return SizedBox(
                          height: rowHeight,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: p.surfaceAlt,
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusSm),
                                  ),
                                ),
                              ),
                              for (final stage in row.stages)
                                _segment(stage, width, totalMs),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _segment(GanttStage stage, double width, int totalMs) {
    final end = stage.end ?? rangeEnd;
    final startFraction =
        (stage.start.difference(rangeStart).inMilliseconds / totalMs)
            .clamp(0.0, 1.0);
    final endFraction =
        (end.difference(rangeStart).inMilliseconds / totalMs).clamp(0.0, 1.0);
    final left = startFraction * width;
    final segWidth = ((endFraction - startFraction) * width)
        .clamp(3.0, width - left < 3 ? 3.0 : width - left);
    return Positioned(
      left: left,
      width: segWidth,
      top: 4,
      bottom: 4,
      child: Tooltip(
        message: stage.label,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: stage.color,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
          ),
        ),
      ),
    );
  }
}
