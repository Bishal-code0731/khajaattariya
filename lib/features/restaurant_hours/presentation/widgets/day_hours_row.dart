import 'package:flutter/material.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/restaurant_hours_model.dart';

/// One weekday: open switch plus opening / closing time buttons.
class DayHoursRow extends StatelessWidget {
  const DayHoursRow(
      {super.key, required this.hours, required this.onChanged, this.error});

  final RestaurantHoursModel hours;
  final ValueChanged<RestaurantHoursModel> onChanged;
  final String? error;

  static TimeOfDay _parse(String? t, TimeOfDay fallback) {
    final parts = (t ?? '').split(':');
    if (parts.length != 2) return fallback;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    return (h == null || m == null) ? fallback : TimeOfDay(hour: h, minute: m);
  }

  static String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pick(BuildContext context, {required bool opening}) async {
    final initial = opening
        ? _parse(hours.openTime, const TimeOfDay(hour: 9, minute: 0))
        : _parse(hours.closeTime, const TimeOfDay(hour: 22, minute: 0));
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!),
    );
    if (picked == null) return;
    onChanged(opening
        ? hours.copyWith(openTime: _fmt(picked))
        : hours.copyWith(closeTime: _fmt(picked)));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.s.restaurant;
    final day = s.weekday(hours.weekday);

    final dayAndSwitch = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(day,
                  style: context.text.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(hours.isOpen ? s.open : s.closedAllDay,
                  style: context.text.caption.copyWith(
                      color: hours.isOpen ? p.success : p.textSecondary)),
            ],
          ),
        ),
        Semantics(
          label: s.dayOpenSwitch(day),
          child: Switch(
            value: hours.isOpen,
            onChanged: (v) => onChanged(hours.copyWith(
              isOpen: v,
              openTime: hours.openTime ?? '09:00',
              closeTime: hours.closeTime ?? '22:00',
            )),
          ),
        ),
      ],
    );

    final times = Row(
      children: [
        Expanded(
          child: _TimeButton(
            label: s.opensAt,
            time: hours.openTime ?? '09:00',
            semantics: s.changeOpenTime(day),
            hasError: error != null,
            onTap: () => _pick(context, opening: true),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _TimeButton(
            label: s.closesAt,
            time: hours.closeTime ?? '22:00',
            semantics: s.changeCloseTime(day),
            hasError: error != null,
            onTap: () => _pick(context, opening: false),
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 560;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (wide)
              Row(
                children: [
                  Expanded(flex: 2, child: dayAndSwitch),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                      flex: 3,
                      child: hours.isOpen ? times : const SizedBox.shrink()),
                ],
              )
            else ...[
              dayAndSwitch,
              if (hours.isOpen) ...[
                const SizedBox(height: AppSpacing.sm),
                times
              ],
            ],
            if (error != null && hours.isOpen) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(Icons.error_outline_rounded, size: 16, color: p.error),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                      child: Text(error!,
                          style:
                              context.text.caption.copyWith(color: p.error))),
                ],
              ),
            ],
          ],
        );
      }),
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.time,
    required this.semantics,
    required this.hasError,
    required this.onTap,
  });

  final String label;
  final String time;
  final String semantics;
  final bool hasError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = BorderRadius.circular(AppSpacing.radiusMd);
    return Semantics(
      button: true,
      label: '$semantics, $time',
      excludeSemantics: true,
      child: Material(
        color: p.surfaceAlt,
        shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: hasError ? p.error : p.border)),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded,
                      size: 18, color: p.textSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(label,
                            style: context.text.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(time, style: context.text.label),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
