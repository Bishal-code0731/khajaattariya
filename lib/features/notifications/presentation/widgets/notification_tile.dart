import 'package:flutter/material.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/models/notification_model.dart';

/// One notification row: type icon, title (bold while unread), body, time, unread dot.
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismissed,
  });

  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final n = notification;
    final (IconData icon, Color fg, Color bg) = switch (n.type) {
      'new_order' => (Icons.storefront_outlined, p.onBrandSoft, p.brandSoft),
      'order_status' => (
          Icons.delivery_dining_outlined,
          p.onBrandSoft,
          p.brandSoft
        ),
      'promo' => (Icons.local_offer_outlined, p.onAccent, p.accentSoft),
      _ => (Icons.campaign_outlined, p.info, p.infoSoft),
    };

    final unreadLabel = n.isRead ? '' : '${context.s.account.unread}. ';
    return Dismissible(
      key: ValueKey(n.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        color: p.errorSoft,
        child: Icon(Icons.delete_outline_rounded, color: p.error),
      ),
      child: Semantics(
        button: true,
        label: '$unreadLabel${n.title}. ${n.body}',
        excludeSemantics: true,
        child: Material(
          color: n.isRead ? p.background : p.surface,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                  vertical: AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: bg,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd)),
                    child: Icon(icon, size: 20, color: fg),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                n.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: n.isRead
                                    ? context.text.body
                                    : context.text.label
                                        .copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(AppFormat.timeAgo(context, n.createdAt),
                                style: context.text.hint),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          n.body,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: n.isRead
                              ? context.text.caption
                              : context.text.secondary,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: AppSpacing.lg,
                    child: n.isRead
                        ? null
                        : Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                    color: p.brand, shape: BoxShape.circle),
                              ),
                            ),
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
