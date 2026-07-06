import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../order_timeline_provider.dart';

/// Builds one [GanttStage] per timeline event — each stage runs from its
/// own timestamp to the next event's timestamp, or to [now] if it's the
/// most recent (still-ongoing) stage. Shared by every Gantt view so the
/// stage-color mapping only lives in one place.
List<GanttStage> ganttStagesFromTimeline(List<OrderTimelineEvent> events, DateTime now) {
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
    case 'pending':   return AppColors.statusPending;
    case 'confirmed': return AppColors.statusConfirmed;
    case 'preparing': return AppColors.statusPreparing;
    case 'ready':     return AppColors.statusReady;
    case 'picked_up': return AppColors.statusDelivering;
    case 'delivered': return AppColors.statusDelivered;
    case 'cancelled': return AppColors.statusCancelled;
    default:          return AppColors.textHint;
  }
}

/// One colored stage within a Gantt row (e.g. "preparing", 10:02–10:14).
class GanttStage {
  final String label;
  final Color color;
  final DateTime start;

  /// Null means this stage is still ongoing — it's drawn out to
  /// [AppGanttChart.rangeEnd] (usually "now") instead of a fixed width.
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

/// A horizontal timeline/Gantt chart: one row per item, with colored
/// segments showing how long it spent in each stage. Built as a plain
/// proportional-width renderer (Row/Stack) rather than forcing fl_chart's
/// vertical-bar primitives into a horizontal-timeline shape they don't
/// fit — no new dependency either way.
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
    this.rowHeight = 40,
  });

  @override
  Widget build(BuildContext context) {
    final totalMs = rangeEnd.difference(rangeStart).inMilliseconds.clamp(1, double.maxFinite.toInt());

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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: labelWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          row.label,
                          style: AppTypography.labelSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (row.subtitle != null)
                          Text(
                            row.subtitle!,
                            style: AppTypography.bodySmall.copyWith(fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: SizedBox(
                      height: rowHeight,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.divider,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                          ),
                          for (final stage in row.stages)
                            _StageSegment(
                              stage: stage,
                              rangeStart: rangeStart,
                              rangeEnd: rangeEnd,
                              totalMs: totalMs,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _StageSegment extends StatelessWidget {
  final GanttStage stage;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final int totalMs;

  const _StageSegment({
    required this.stage,
    required this.rangeStart,
    required this.rangeEnd,
    required this.totalMs,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveEnd = stage.end ?? rangeEnd;
    final startFraction = (stage.start.difference(rangeStart).inMilliseconds / totalMs).clamp(0.0, 1.0);
    final endFraction = (effectiveEnd.difference(rangeStart).inMilliseconds / totalMs).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final left = startFraction * width;
        final segWidth = ((endFraction - startFraction) * width).clamp(2.0, width);
        return Positioned(
          left: left,
          width: segWidth,
          top: 0,
          bottom: 0,
          child: Tooltip(
            message: stage.label,
            child: Container(
              decoration: BoxDecoration(
                color: stage.color,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
            ),
          ),
        );
      },
    );
  }
}
