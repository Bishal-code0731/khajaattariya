import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';

/// Cached remote image with a calm placeholder and a food icon fallback.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackIcon = Icons.restaurant_rounded,
    this.semanticLabel,
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData fallbackIcon;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    Widget placeholder() => Container(
          width: width,
          height: height,
          color: p.surfaceAlt,
          alignment: Alignment.center,
          child: Icon(fallbackIcon,
              color: p.textHint, size: ((height ?? 48) * 0.35).clamp(18, 40)),
        );

    final hasUrl = url != null && url!.trim().isNotEmpty;
    Widget image = hasUrl
        ? CachedNetworkImage(
            imageUrl: url!,
            width: width,
            height: height,
            fit: fit,
            memCacheWidth: width != null && width!.isFinite
                ? (width! * dpr).round()
                : null,
            fadeInDuration: const Duration(milliseconds: 180),
            placeholder: (_, __) =>
                Container(width: width, height: height, color: p.surfaceAlt),
            errorWidget: (_, __, ___) => placeholder(),
          )
        : placeholder();

    image = semanticLabel != null
        ? Semantics(image: true, label: semanticLabel, child: image)
        : ExcludeSemantics(child: image);
    return borderRadius == null
        ? image
        : ClipRRect(borderRadius: borderRadius!, child: image);
  }
}
