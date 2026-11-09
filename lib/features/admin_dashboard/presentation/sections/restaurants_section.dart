import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../application/admin_actions.dart';
import '../../application/admin_queries.dart';
import '../../domain/admin_models.dart';
import '../widgets/admin_busy.dart';
import '../widgets/admin_filter_bar.dart';
import '../widgets/admin_list.dart';
import '../widgets/admin_note_dialog.dart';
import '../widgets/admin_tag.dart';

/// Restaurant approvals and visibility: Pending / Active / Inactive.
class RestaurantsSection extends ConsumerStatefulWidget {
  const RestaurantsSection({super.key});

  @override
  ConsumerState<RestaurantsSection> createState() => _RestaurantsSectionState();
}

class _RestaurantsSectionState extends ConsumerState<RestaurantsSection> {
  RestaurantQueue _queue = RestaurantQueue.pending;

  @override
  Widget build(BuildContext context) {
    final s = context.s.admin;
    final async = ref.watch(adminRestaurantsProvider);
    final all = async.valueOrNull ?? const <AdminRestaurant>[];
    int count(RestaurantQueue q) => all.where((r) => r.queue == q).length;

    return AdminAsyncList<AdminRestaurant>(
      value: async.whenData((list) {
        final items = list.where((r) => r.queue == _queue).toList();
        // Oldest first for the review queue (first come, first served).
        if (_queue == RestaurantQueue.pending) {
          items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        }
        return items;
      }),
      onRefresh: () => ref.refresh(adminRestaurantsProvider.future),
      header: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: AdminFilterBar<RestaurantQueue>(
          selected: _queue,
          onSelected: (q) => setState(() => _queue = q),
          options: [
            AdminFilterOption(RestaurantQueue.pending, s.pending,
                count: count(RestaurantQueue.pending)),
            AdminFilterOption(RestaurantQueue.active, s.active,
                count: count(RestaurantQueue.active)),
            AdminFilterOption(RestaurantQueue.inactive, s.inactive,
                count: count(RestaurantQueue.inactive)),
          ],
        ),
      ),
      empty: AppEmptyState(
        icon: _queue == RestaurantQueue.pending
            ? Icons.task_alt_rounded
            : Icons.storefront_outlined,
        title: _queue == RestaurantQueue.pending
            ? s.restaurantsPendingEmpty
            : s.restaurantsEmpty,
        subtitle: _queue == RestaurantQueue.pending
            ? s.restaurantsPendingEmptyHint
            : null,
        compact: true,
      ),
      itemBuilder: (context, r) =>
          _RestaurantRow(key: ValueKey(r.id), restaurant: r),
    );
  }
}

class _RestaurantRow extends ConsumerStatefulWidget {
  const _RestaurantRow({super.key, required this.restaurant});
  final AdminRestaurant restaurant;

  @override
  ConsumerState<_RestaurantRow> createState() => _RestaurantRowState();
}

class _RestaurantRowState extends ConsumerState<_RestaurantRow> with AdminBusy {
  AdminActions get _actions => ref.read(adminActionsProvider);
  AdminRestaurant get _r => widget.restaurant;

  Future<void> _approve() async {
    final s = context.s.admin;
    final ok = await AppDialog.confirm(context,
        title: s.approveRestaurantTitle(_r.name),
        message: s.approveRestaurantMessage,
        confirmLabel: s.approve,
        icon: Icons.verified_rounded);
    if (!ok || !mounted) return;
    await runAction('approve', () => _actions.approveRestaurant(_r.id),
        success: s.restaurantApproved);
  }

  Future<void> _reject() async {
    final s = context.s.admin;
    final note = await showAdminNoteDialog(context,
        title: s.rejectRestaurantTitle(_r.name));
    if (note == null || !mounted) return;
    await runAction('reject', () => _actions.rejectRestaurant(_r.id, note),
        success: s.restaurantRejected);
  }

  Future<void> _setActive(bool active) async {
    final s = context.s.admin;
    if (!active) {
      final ok = await AppDialog.confirm(context,
          title: s.deactivateTitle(_r.name),
          message: s.deactivateMessage,
          confirmLabel: s.deactivate,
          destructive: true,
          icon: Icons.visibility_off_rounded);
      if (!ok || !mounted) return;
    }
    await runAction('active', () => _actions.setRestaurantActive(_r.id, active),
        success: active ? s.restaurantReactivated : s.restaurantDeactivated);
  }

  Future<void> _setFeatured(bool featured) => runAction(
      'featured', () => _actions.setRestaurantFeatured(_r.id, featured),
      success:
          featured ? context.s.admin.featuredOn : context.s.admin.featuredOff);

  @override
  Widget build(BuildContext context) {
    final s = context.s.admin;
    final p = context.palette;
    final r = _r;
    final owner =
        r.ownerName?.trim().isNotEmpty == true ? r.ownerName! : s.unknown;
    final details = [
      if (r.cuisine.isNotEmpty) r.cuisine,
      if (r.ownerPhone?.isNotEmpty == true) AppFormat.phone(r.ownerPhone!),
      AppFormat.date(context, r.createdAt),
    ].join(' · ');

    final List<Widget> actions = switch (r.queue) {
      RestaurantQueue.pending => [
          AppButton(
            label: s.reject,
            variant: AppButtonVariant.outline,
            color: p.error,
            size: AppButtonSize.small,
            expand: false,
            isLoading: busy == 'reject',
            onPressed: isBusy ? null : _reject,
          ),
          AppButton(
            label: s.approve,
            leadingIcon: Icons.check_rounded,
            size: AppButtonSize.small,
            expand: false,
            isLoading: busy == 'approve',
            onPressed: isBusy ? null : _approve,
          ),
        ],
      RestaurantQueue.active => [
          AppButton(
            label: s.deactivate,
            variant: AppButtonVariant.outline,
            size: AppButtonSize.small,
            expand: false,
            isLoading: busy == 'active',
            onPressed: isBusy ? null : () => _setActive(false),
          ),
        ],
      RestaurantQueue.inactive => [
          r.isRejected
              ? AppButton(
                  label: s.approve,
                  leadingIcon: Icons.check_rounded,
                  variant: AppButtonVariant.tonal,
                  size: AppButtonSize.small,
                  expand: false,
                  isLoading: busy == 'approve',
                  onPressed: isBusy ? null : _approve,
                )
              : AppButton(
                  label: s.reactivate,
                  leadingIcon: Icons.visibility_rounded,
                  variant: AppButtonVariant.tonal,
                  size: AppButtonSize.small,
                  expand: false,
                  isLoading: busy == 'active',
                  onPressed: isBusy ? null : () => _setActive(true),
                ),
        ],
    };

    return AdminRow(
      leading: AppNetworkImage(
        url: r.imageUrl,
        width: 56,
        height: 56,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        fallbackIcon: Icons.storefront_rounded,
      ),
      title: r.name.isEmpty ? s.unknown : r.name,
      lines: [
        s.owner(owner),
        details,
        if (r.address?.isNotEmpty == true) r.address!
      ],
      tags: [
        if (r.isFeatured)
          AdminTag(
              label: s.featured,
              icon: Icons.star_rounded,
              tone: AdminTone.warning),
        if (r.isRejected)
          AdminTag(
              label: s.rejectedNote(r.approvalNote!),
              icon: Icons.block_rounded,
              tone: AdminTone.error),
        if (r.queue == RestaurantQueue.inactive && !r.isRejected)
          AdminTag(label: s.inactive, icon: Icons.visibility_off_rounded),
      ],
      below: r.queue == RestaurantQueue.active
          ? _FeatureSwitch(
              value: r.isFeatured,
              loading: busy == 'featured',
              onChanged: isBusy ? null : _setFeatured)
          : null,
      actions: actions,
    );
  }
}

/// "Feature on home" switch, attached under an active restaurant's row.
class _FeatureSwitch extends StatelessWidget {
  const _FeatureSwitch(
      {required this.value, required this.loading, required this.onChanged});
  final bool value;
  final bool loading;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final s = context.s.admin;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          Icon(Icons.star_outline_rounded,
              size: 18, color: context.palette.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(s.featureOnHome, style: context.text.caption)),
          if (loading)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: AppLoader(size: 20),
            )
          else
            Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
