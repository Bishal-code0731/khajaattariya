import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/s.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/error_state_view.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../application/restaurant_hours_provider.dart';
import '../domain/models/restaurant_hours_model.dart';
import 'widgets/day_hours_row.dart';
import '../../../shared/widgets/busy_overlay.dart';

/// Weekly opening hours (Mon–Sun), saved in one batch.
class RestaurantHoursScreen extends ConsumerStatefulWidget {
  const RestaurantHoursScreen({super.key, required this.restaurantId});

  final String restaurantId;

  @override
  ConsumerState<RestaurantHoursScreen> createState() =>
      _RestaurantHoursScreenState();
}

class _RestaurantHoursScreenState extends ConsumerState<RestaurantHoursScreen> {
  List<RestaurantHoursModel>? _hours;
  bool _dirty = false;
  bool _saving = false;

  /// Always 7 rows (weekday 1 = Monday … 7 = Sunday); missing days get 09:00–22:00 defaults.
  List<RestaurantHoursModel> _complete(List<RestaurantHoursModel> fromDb) {
    final byDay = {for (final h in fromDb) h.weekday: h};
    return [
      for (var d = 1; d <= 7; d++)
        byDay[d] ??
            RestaurantHoursModel(
              id: '',
              restaurantId: widget.restaurantId,
              weekday: d,
              isOpen: true,
              openTime: '09:00',
              closeTime: '22:00',
            ),
    ];
  }

  // 24h "HH:mm" strings compare correctly as text.
  static bool _valid(RestaurantHoursModel h) =>
      !h.isOpen || (h.openTime ?? '').compareTo(h.closeTime ?? '') < 0;

  void _update(int index, RestaurantHoursModel value) => setState(() {
        _hours![index] = value;
        _dirty = true;
      });

  void _copyMonday() {
    final mon = _hours!.first;
    setState(() {
      _hours = [
        mon,
        for (final h in _hours!.skip(1))
          h.copyWith(
              isOpen: mon.isOpen,
              openTime: mon.openTime,
              closeTime: mon.closeTime),
      ];
      _dirty = true;
    });
    AppSnackbar.info(context, context.s.restaurant.mondayCopied);
  }

  Future<void> _save() async {
    final hours = _hours;
    if (hours == null || _saving) return;
    final s = context.s.restaurant;
    final invalid = hours.where((h) => !_valid(h)).toList();
    if (invalid.isNotEmpty) {
      AppSnackbar.warning(
          context, s.closeBeforeOpen(s.weekday(invalid.first.weekday)));
      return;
    }
    setState(() => _saving = true);
    final notifier =
        ref.read(restaurantHoursNotifierProvider(widget.restaurantId).notifier);
    final ok = await notifier.saveHours(hours);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (ok) _dirty = false;
    });
    if (ok) {
      AppSnackbar.success(context, s.hoursSaved);
    } else {
      AppSnackbar.error(context,
          ref.read(restaurantHoursNotifierProvider(widget.restaurantId)).error);
    }
  }

  @override
  Widget build(BuildContext context) =>
      BusyOverlay(busy: _saving, child: _buildBusyContent(context));

  Widget _buildBusyContent(BuildContext context) {
    final s = context.s.restaurant;
    final p = context.palette;
    final hoursAsync = ref.watch(restaurantHoursProvider(widget.restaurantId));
    if (_hours == null && hoursAsync.hasValue) {
      _hours = _complete(hoursAsync.value!);
    }

    Widget body;
    if (_hours == null) {
      body = hoursAsync.hasError
          ? AppErrorState(
              error: hoursAsync.error,
              onRetry: () =>
                  ref.invalidate(restaurantHoursProvider(widget.restaurantId)),
            )
          : const AppShimmerCardList(count: 7, itemHeight: 48);
    } else {
      final hours = _hours!;
      body = SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal,
            AppSpacing.lg, AppSpacing.screenHorizontal, AppSpacing.xxl),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppButton(
                    label: s.copyMondayToAll,
                    leadingIcon: Icons.copy_all_rounded,
                    variant: AppButtonVariant.tonal,
                    size: AppButtonSize.medium,
                    expand: false,
                    onPressed: _saving ? null : _copyMonday,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < hours.length; i++) ...[
                        if (i > 0) Divider(height: 1, color: p.border),
                        DayHoursRow(
                          hours: hours[i],
                          error:
                              _valid(hours[i]) ? null : s.closeBeforeOpenShort,
                          onChanged: (v) => _update(i, v),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppTopBar(title: s.hoursTitle, subtitle: s.hoursSubtitle),
      body: body,
      bottomNavigationBar: _hours == null
          ? null
          : Container(
              decoration: BoxDecoration(
                  color: p.surface,
                  border: Border(top: BorderSide(color: p.border))),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Center(
                    heightFactor: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_dirty)
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: Text(s.unsavedChanges,
                                  style: context.text.caption),
                            ),
                          AppButton(
                              label: s.saveHours,
                              isLoading: _saving,
                              onPressed: _save),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
