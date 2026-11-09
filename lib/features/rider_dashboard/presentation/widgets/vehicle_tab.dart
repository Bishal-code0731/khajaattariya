import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/s.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/error_state_view.dart';
import '../../../../shared/widgets/shimmer_loader.dart';
import '../../../rider/application/rider_provider.dart';
import '../../../rider/domain/models/rider_model.dart';
import 'approval_banner.dart';
import 'rider_page.dart';
import 'vehicle_form.dart';

/// Registration (no rider row yet) or the rider's status + vehicle.
class VehicleTab extends ConsumerStatefulWidget {
  const VehicleTab(
      {super.key,
      required this.riderId,
      required this.phone,
      required this.onLogout});

  final String riderId;
  final String? phone;
  final Future<void> Function() onLogout;

  @override
  ConsumerState<VehicleTab> createState() => _VehicleTabState();
}

class _VehicleTabState extends ConsumerState<VehicleTab> {
  bool _editing = false;
  bool _loggingOut = false;

  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    await widget.onLogout();
    if (mounted) setState(() => _loggingOut = false);
  }

  @override
  Widget build(BuildContext context) {
    final r = context.s.rider;
    final profileAsync = ref.watch(riderProfileProvider(widget.riderId));

    return profileAsync.when(
      skipLoadingOnReload: true,
      loading: () => RiderPage(
        children: [
          AppShimmer(
              height: 120,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
          const SizedBox(height: AppSpacing.lg),
          AppShimmer(
              height: 200,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        ],
      ),
      error: (e, _) => AppErrorState(
        message: r.profileLoadError,
        error: e,
        onRetry: () => ref.invalidate(riderProfileProvider(widget.riderId)),
      ),
      data: (rider) {
        final footer =
            _AccountActions(onLogout: _logout, loggingOut: _loggingOut);
        if (rider == null) {
          return RiderPage(
            maxWidth: AppSpacing.maxFormWidth,
            children: [
              _RegisterIntro(),
              const SizedBox(height: AppSpacing.lg),
              AppCard(child: VehicleForm(riderId: widget.riderId)),
              const SizedBox(height: AppSpacing.xl),
              footer,
            ],
          );
        }
        final canEdit = !rider.isApproved;
        return RiderPage(
          maxWidth: 640,
          onRefresh: () async {
            ref.invalidate(riderProfileProvider(widget.riderId));
            try {
              await ref.read(riderProfileProvider(widget.riderId).future);
            } catch (_) {}
          },
          children: [
            ApprovalBanner(rider: rider, showApproved: true),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: _editing && canEdit
                  ? VehicleForm(
                      riderId: widget.riderId,
                      initialType: rider.vehicleType,
                      initialNumber: rider.vehicleNumber,
                      isUpdate: true,
                      onDone: () => setState(() => _editing = false),
                    )
                  : _VehicleSummary(
                      rider: rider,
                      phone: widget.phone,
                      onEdit: canEdit
                          ? () => setState(() => _editing = true)
                          : null,
                    ),
            ),
            const SizedBox(height: AppSpacing.xl),
            footer,
          ],
        );
      },
    );
  }
}

class _RegisterIntro extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.s.rider;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
              color: p.brandSoft,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
          child: Icon(Icons.delivery_dining_rounded,
              size: 30, color: p.onBrandSoft),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(r.registerTitle,
            style: AppTypography.headingMedium.copyWith(color: p.textPrimary)),
        const SizedBox(height: AppSpacing.xs),
        Text(r.registerBody,
            style: AppTypography.bodyMedium.copyWith(color: p.textSecondary)),
      ],
    );
  }
}

class _VehicleSummary extends StatelessWidget {
  const _VehicleSummary(
      {required this.rider, required this.phone, this.onEdit});

  final RiderModel rider;
  final String? phone;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.s.rider;
    final c = context.s.common;
    final number = rider.vehicleNumber?.trim() ?? '';
    final phoneText = (phone ?? rider.phone ?? '').trim();

    Widget row(IconData icon, String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Icon(icon, size: 20, color: p.textSecondary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                  child: Text(label,
                      style: AppTypography.bodyMedium
                          .copyWith(color: p.textSecondary))),
              Flexible(
                child: Text(value,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(
                        color: p.textPrimary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                  color: p.brandSoft,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
              child: Icon(riderVehicleIcon(rider.vehicleType),
                  size: 30, color: p.onBrandSoft),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.vehicleTitle,
                      style: AppTypography.labelSmall
                          .copyWith(color: p.textSecondary)),
                  Text(r.vehicleTypeLabel(rider.vehicleType),
                      style: AppTypography.headingSmall
                          .copyWith(color: p.textPrimary)),
                ],
              ),
            ),
            if (onEdit != null)
              AppButton(
                label: r.editVehicle,
                leadingIcon: Icons.edit_outlined,
                variant: AppButtonVariant.text,
                size: AppButtonSize.small,
                expand: false,
                onPressed: onEdit,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Divider(height: 1, color: p.border),
        const SizedBox(height: AppSpacing.xs),
        row(Icons.badge_outlined, r.vehicleNumber,
            number.isEmpty ? r.notAdded : number),
        row(Icons.phone_outlined, c.fieldPhone,
            phoneText.isEmpty ? r.notAdded : AppFormat.phone(phoneText)),
        row(Icons.delivery_dining_outlined, r.totalDeliveries,
            '${rider.totalDeliveries}'),
        row(Icons.account_balance_wallet_outlined, r.totalEarned,
            AppFormat.money(context, rider.totalEarnings)),
      ],
    );
  }
}

class _AccountActions extends StatelessWidget {
  const _AccountActions({required this.onLogout, required this.loggingOut});

  final Future<void> Function() onLogout;
  final bool loggingOut;

  @override
  Widget build(BuildContext context) {
    final r = context.s.rider;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton(
          label: r.accountSettings,
          leadingIcon: Icons.manage_accounts_outlined,
          variant: AppButtonVariant.tonal,
          onPressed: () => context.push(RouteNames.profile),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: context.s.common.logout,
          leadingIcon: Icons.logout_rounded,
          variant: AppButtonVariant.text,
          isLoading: loggingOut,
          onPressed: loggingOut ? null : onLogout,
        ),
      ],
    );
  }
}
