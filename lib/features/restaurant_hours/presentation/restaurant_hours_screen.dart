import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/glass_card.dart';
import '../application/restaurant_hours_provider.dart';
import '../domain/models/restaurant_hours_model.dart';

class RestaurantHoursScreen extends ConsumerStatefulWidget {
  final String restaurantId;
  const RestaurantHoursScreen({super.key, required this.restaurantId});

  @override
  ConsumerState<RestaurantHoursScreen> createState() =>
      _RestaurantHoursScreenState();
}

class _RestaurantHoursScreenState
    extends ConsumerState<RestaurantHoursScreen> {
  List<RestaurantHoursModel>? _editableHours;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final hoursAsync =
    ref.watch(restaurantHoursProvider(widget.restaurantId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Opening Hours'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: hoursAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, __) =>
        const Center(child: Text('Could not load hours')),
        data: (hours) {
          // Initialise editable copy once
          _editableHours ??= List.from(hours);

          // If DB returned empty (first time), create 7 defaults
          if (_editableHours!.isEmpty) {
            _editableHours = List.generate(
              7,
                  (i) => RestaurantHoursModel(
                id: '',
                restaurantId: widget.restaurantId,
                weekday: i + 1,
                isOpen: true,
                openTime: '09:00',
                closeTime: '22:00',
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                    vertical: AppSpacing.md,
                  ),
                  itemCount: _editableHours!.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    return _DayRow(
                      hours: _editableHours![index],
                      onChanged: (updated) {
                        setState(() {
                          _editableHours![index] = updated;
                        });
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                child: AppButton(
                  label: 'Save Hours',
                  isLoading: _isSaving,
                  onPressed: _save,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          );
        },
      ),
    );
  }

  Future<void> _save() async {
    if (_editableHours == null) return;
    setState(() => _isSaving = true);

    final success = await ref
        .read(restaurantHoursNotifierProvider(widget.restaurantId)
        .notifier)
        .saveHours(_editableHours!);

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Hours saved!' : 'Failed to save hours'),
        backgroundColor: success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  final RestaurantHoursModel hours;
  final ValueChanged<RestaurantHoursModel> onChanged;

  const _DayRow({required this.hours, required this.onChanged});

  Future<void> _pickTime(
      BuildContext context, bool isOpen) async {
    final initial = _parseTime(isOpen ? hours.openTime : hours.closeTime);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    onChanged(isOpen
        ? hours.copyWith(openTime: formatted)
        : hours.copyWith(closeTime: formatted));
  }

  TimeOfDay _parseTime(String? t) {
    if (t == null) return const TimeOfDay(hour: 9, minute: 0);
    final parts = t.split(':');
    return TimeOfDay(
        hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      borderRadius: AppSpacing.radiusLg,
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(hours.dayName,
                style: AppTypography.labelMedium),
          ),
          Switch(
            value: hours.isOpen,
            activeColor: AppColors.primary,
            onChanged: (v) => onChanged(hours.copyWith(isOpen: v)),
          ),
          if (hours.isOpen) ...[
            const Spacer(),
            _TimeButton(
              time: hours.openTime ?? '09:00',
              onTap: () => _pickTime(context, true),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm),
              child: Text('–',
                  style: AppTypography.bodyMedium),
            ),
            _TimeButton(
              time: hours.closeTime ?? '22:00',
              onTap: () => _pickTime(context, false),
            ),
          ] else ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius:
                BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text('Closed',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.error)),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String time;
  final VoidCallback onTap;

  const _TimeButton({required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.access_time_rounded,
                size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(time,
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}