import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../application/owner_restaurant_provider.dart';
import '../../domain/models/owner_restaurant.dart';

/// "Open / Closed" switch for taking orders.
class OpenStatusSwitch extends ConsumerStatefulWidget {
  const OpenStatusSwitch(
      {super.key,
      required this.restaurant,
      required this.ownerId,
      this.expand = false});

  final OwnerRestaurant restaurant;
  final String ownerId;

  /// Full-width row (phone header) instead of a compact pill (wide header).
  final bool expand;

  @override
  ConsumerState<OpenStatusSwitch> createState() => _OpenStatusSwitchState();
}

class _OpenStatusSwitchState extends ConsumerState<OpenStatusSwitch> {
  bool _busy = false;
  bool? _pending; // optimistic value while saving

  bool get _isOpen => _pending ?? widget.restaurant.isOpen;

  Future<void> _change(bool open) async {
    if (_busy) return;
    final s = context.s.restaurant;
    if (!open) {
      final ok = await AppDialog.confirm(
        context,
        title: s.closeConfirmTitle,
        message: s.closeConfirmMessage,
        confirmLabel: s.closeConfirmAction,
        destructive: true,
        icon: Icons.storefront_outlined,
      );
      if (!ok || !mounted) return;
    }
    setState(() {
      _busy = true;
      _pending = open;
    });
    try {
      await ref
          .read(ownerRestaurantActionsProvider)
          .setOpen(widget.restaurant.id, open);
      ref.invalidate(ownerRestaurantProvider(widget.ownerId));
      if (mounted) {
        AppSnackbar.success(context, open ? s.nowOpenToast : s.nowClosedToast);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _pending = null);
        AppSnackbar.error(context, e);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void didUpdateWidget(covariant OpenStatusSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Fresh data arrived — drop the optimistic value once it matches.
    if (!_busy && _pending == widget.restaurant.isOpen) _pending = null;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.s.restaurant;
    final open = _isOpen;
    final fg = open ? p.success : p.textSecondary;

    final status = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(open ? Icons.storefront_rounded : Icons.do_not_disturb_on_outlined,
            size: 20, color: fg),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(open ? s.open : s.closed,
                  style: context.text.label.copyWith(color: fg),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              if (widget.expand)
                Text(open ? s.takingOrders : s.notTakingOrders,
                    style: context.text.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );

    final control = _busy
        ? const SizedBox(
            width: 52, height: 32, child: Center(child: AppLoader(size: 20)))
        : Switch(value: open, onChanged: _change);

    return Semantics(
      label: s.openSwitchLabel,
      toggled: open,
      child: Container(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.xs,
          top: widget.expand ? AppSpacing.xs : 0,
          bottom: widget.expand ? AppSpacing.xs : 0,
        ),
        decoration: BoxDecoration(
          color: open ? p.successSoft : p.surfaceAlt,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (widget.expand)
              Expanded(child: status)
            else
              Flexible(child: status),
            const SizedBox(width: AppSpacing.sm),
            control,
          ],
        ),
      ),
    );
  }
}
