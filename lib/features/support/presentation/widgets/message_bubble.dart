import 'package:flutter/material.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';

/// One chat message.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.sender,
    required this.sentAt,
    required this.isMine,
  });

  final String message;
  final String sender;
  final DateTime sentAt;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const r = Radius.circular(AppSpacing.radiusLg);
    const tail = Radius.circular(AppSpacing.radiusXs);
    final maxWidth =
        (MediaQuery.sizeOf(context).width * 0.78).clamp(0.0, 520.0);
    return Semantics(
      label: '$sender, ${AppFormat.dateTime(context, sentAt)}',
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMine)
                Padding(
                  padding: const EdgeInsets.only(
                      left: AppSpacing.xs, bottom: AppSpacing.xxs),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.support_agent_rounded,
                          size: 14, color: p.brand),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(sender,
                            style:
                                context.text.overline.copyWith(color: p.brand),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
                decoration: BoxDecoration(
                  color: isMine ? p.brand : p.surface,
                  border: isMine ? null : Border.all(color: p.border),
                  borderRadius: BorderRadius.only(
                    topLeft: r,
                    topRight: r,
                    bottomLeft: isMine ? r : tail,
                    bottomRight: isMine ? tail : r,
                  ),
                ),
                child: SelectableText(
                  message,
                  style: context.text.body
                      .copyWith(color: isMine ? p.onBrand : p.textPrimary),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xs, AppSpacing.xxs, AppSpacing.xs, 0),
                child: Text(AppFormat.dateTime(context, sentAt),
                    style: context.text.hint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
