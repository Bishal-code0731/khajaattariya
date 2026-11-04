import 'package:flutter/material.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/order_timeline_provider.dart';
import '../../domain/models/order_model.dart';

/// The happy path every order walks through, in order.
const orderSteps = [
  OrderStatus.pending,
  OrderStatus.confirmed,
  OrderStatus.preparing,
  OrderStatus.ready,
  OrderStatus.pickedUp,
  OrderStatus.delivered,
];

String orderStepLabel(BuildContext context, OrderStatus step) {
  final o = context.s.orders;
  return switch (step) {
    OrderStatus.pending => o.stepPlaced,
    OrderStatus.confirmed => o.stepAccepted,
    OrderStatus.preparing => o.stepPreparing,
    OrderStatus.ready => o.stepReady,
    OrderStatus.pickedUp => o.stepOnTheWay,
    OrderStatus.delivered => o.stepDelivered,
    OrderStatus.cancelled => context.s.common.statusCancelled,
  };
}

/// Slim segmented bar for list cards: one segment per step.
class OrderProgressBar extends StatelessWidget {
  const OrderProgressBar({super.key, required this.status});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final current = orderSteps.indexOf(status);
    return ExcludeSemantics(
      child: Row(
        children: [
          for (var i = 0; i < orderSteps.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: i <= current ? p.brand : p.border,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class OrderProgressStepper extends StatelessWidget {
  const OrderProgressStepper({
    super.key,
    required this.status,
    required this.events,
  });

  final OrderStatus status;
  final List<OrderTimelineEvent> events;

  DateTime? _timeOf(OrderStatus step) {
    for (final e in events) {
      if (e.status == step.dbValue) return e.createdAt;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final rows = <_StepData>[];
    if (status == OrderStatus.cancelled) {
      for (final step in orderSteps) {
        final at = _timeOf(step);
        if (at != null) rows.add(_StepData(step, _StepState.done, at));
      }
      if (rows.isEmpty) {
        rows.add(const _StepData(OrderStatus.pending, _StepState.done, null));
      }
      rows.add(_StepData(OrderStatus.cancelled, _StepState.cancelled,
          _timeOf(OrderStatus.cancelled)));
    } else {
      final current = orderSteps.indexOf(status);
      for (var i = 0; i < orderSteps.length; i++) {
        final step = orderSteps[i];
        final state = i < current || status == OrderStatus.delivered
            ? _StepState.done
            : i == current
                ? _StepState.current
                : _StepState.upcoming;
        rows.add(_StepData(step, state, _timeOf(step)));
      }
    }

    return Column(
      children: [
        for (var i = 0; i < rows.length; i++)
          _StepRow(
            data: rows[i],
            isLast: i == rows.length - 1,
            nextReached:
                i + 1 < rows.length && rows[i + 1].state != _StepState.upcoming,
          ),
      ],
    );
  }
}

enum _StepState { done, current, upcoming, cancelled }

class _StepData {
  const _StepData(this.step, this.state, this.at);
  final OrderStatus step;
  final _StepState state;
  final DateTime? at;
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.data,
    required this.isLast,
    required this.nextReached,
  });

  final _StepData data;
  final bool isLast;
  final bool nextReached;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.text;
    final o = context.s.orders;
    final label = orderStepLabel(context, data.step);
    final time = data.at == null ? null : AppFormat.time(context, data.at!);

    final (Color dotColor, Widget dotChild) = switch (data.state) {
      _StepState.done => (
          p.brand,
          Icon(Icons.check_rounded, size: 14, color: p.onBrand),
        ),
      _StepState.current => (
          p.brandSoft,
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: p.brand, shape: BoxShape.circle),
          ),
        ),
      _StepState.upcoming => (p.surfaceAlt, const SizedBox.shrink()),
      _StepState.cancelled => (
          p.error,
          Icon(Icons.close_rounded, size: 14, color: p.surface),
        ),
    };

    final labelStyle = switch (data.state) {
      _StepState.done => text.body,
      _StepState.current => text.label.copyWith(color: p.brand),
      _StepState.upcoming => text.body.copyWith(color: p.textHint),
      _StepState.cancelled => text.label.copyWith(color: p.error),
    };

    final semantic = switch (data.state) {
      _StepState.done ||
      _StepState.cancelled =>
        time == null ? label : o.stepDone(label, time),
      _StepState.current => o.stepCurrent(label),
      _StepState.upcoming => o.stepUpcoming(label),
    };

    return Semantics(
      label: semantic,
      excludeSemantics: true,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 24,
              child: Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      border: data.state == _StepState.upcoming
                          ? Border.all(color: p.border, width: 1.5)
                          : data.state == _StepState.current
                              ? Border.all(color: p.brand, width: 1.5)
                              : null,
                    ),
                    child: dotChild,
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        color: nextReached ? p.brand : p.border,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  top: 2,
                  bottom: isLast ? 0 : AppSpacing.lg,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(label, style: labelStyle)),
                    if (time != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Text(time, style: text.hint),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
