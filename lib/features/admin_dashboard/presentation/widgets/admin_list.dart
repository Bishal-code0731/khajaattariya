import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/error_state_view.dart';
import '../../../../shared/widgets/shimmer_loader.dart';

class AdminAsyncList<T> extends StatelessWidget {
  const AdminAsyncList({
    super.key,
    required this.value,
    required this.onRefresh,
    required this.itemBuilder,
    required this.empty,
    this.header,
    this.footer,
  });

  final AsyncValue<List<T>> value;
  final Future<void> Function() onRefresh;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Widget empty;
  final Widget? header;
  final Widget? footer;

  static const listPadding = EdgeInsets.fromLTRB(AppSpacing.screenHorizontal,
      AppSpacing.sm, AppSpacing.screenHorizontal, AppSpacing.xxxl);

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (value.hasValue) {
      final items = value.value!;
      body = RefreshIndicator(
        onRefresh: onRefresh,
        child: items.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: AppSpacing.xxl),
                children: [empty, if (footer != null) footer!],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: listPadding,
                itemCount: items.length + (footer != null ? 1 : 0),
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) => i == items.length
                    ? footer!
                    : itemBuilder(context, items[i]),
              ),
      );
    } else if (value.hasError) {
      body = AppErrorState(error: value.error, onRetry: onRefresh);
    } else {
      body = const AppShimmerCardList(count: 6, itemHeight: 56);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null) header!,
        Expanded(child: body),
      ],
    );
  }
}

class AdminRow extends StatelessWidget {
  const AdminRow({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.lines = const [],
    this.tags = const [],
    this.actions = const [],
    this.onTap,
    this.semanticLabel,
    this.below,
    this.borderColor,
    this.color,
  });

  /// Highlight (e.g.
  final Color? borderColor;
  final Color? color;

  final String title;
  final Widget? leading;

  /// Right of the title (amount, time).
  final Widget? trailing;
  final List<String> lines;
  final List<Widget> tags;
  final List<Widget> actions;
  final VoidCallback? onTap;
  final String? semanticLabel;

  /// Extra content under the tags (a switch, a note).
  final Widget? below;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: onTap != null,
      label: semanticLabel,
      child: AppCard(
        onTap: onTap,
        borderColor: borderColor,
        color: color,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth >= 720;
          final info = _info(context);
          if (actions.isEmpty) return info;
          if (wide) {
            return Row(
              children: [
                Expanded(child: info),
                const SizedBox(width: AppSpacing.lg),
                Row(mainAxisSize: MainAxisSize.min, children: _spaced(actions)),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              info,
              const SizedBox(height: AppSpacing.md),
              Row(children: [
                for (final (i, a) in actions.indexed) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(child: a),
                ]
              ]),
            ],
          );
        }),
      ),
    );
  }

  List<Widget> _spaced(List<Widget> items) => [
        for (final (i, a) in items.indexed) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          a,
        ],
      ];

  Widget _info(BuildContext context) {
    final t = context.text;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: AppSpacing.md)
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: Text(title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: t.label)),
                  if (trailing != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    trailing!
                  ],
                ],
              ),
              for (final line in lines)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(line,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.caption),
                ),
              if (tags.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: tags),
              ],
              if (below != null) below!,
            ],
          ),
        ),
      ],
    );
  }
}

/// Initial-letter avatar in a soft tint of [color] (defaults to brand).
class AdminAvatar extends StatelessWidget {
  const AdminAvatar(
      {super.key, required this.name, this.color, this.size = 40});

  final String name;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = color ?? p.brand;
    final initial =
        name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.withValues(alpha: context.isDark ? 0.22 : 0.12),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Text(initial,
            style: context.text.label
                .copyWith(color: context.isDark ? p.textPrimary : c)),
      ),
    );
  }
}
