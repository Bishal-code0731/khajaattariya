import 'package:flutter/material.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../application/restaurant_media_upload.dart';

/// Photo preview + upload / change / remove buttons, used for the restaurant logo and dish photos.
class PhotoUploadField extends StatefulWidget {
  const PhotoUploadField({
    super.key,
    required this.label,
    required this.helper,
    required this.url,
    required this.storagePath,
    required this.onChanged,
    this.fallbackIcon = Icons.storefront_rounded,
    this.previewSize = 96,
  });

  final String label;
  final String helper;
  final String? url;

  /// Called at upload time so each dish photo gets a fresh path.
  final String Function() storagePath;
  final ValueChanged<String?> onChanged;
  final IconData fallbackIcon;
  final double previewSize;

  @override
  State<PhotoUploadField> createState() => _PhotoUploadFieldState();
}

class _PhotoUploadFieldState extends State<PhotoUploadField> {
  bool _uploading = false;

  Future<void> _upload() async {
    if (_uploading) return;
    setState(() => _uploading = true);
    try {
      final url = await uploadRestaurantMedia(widget.storagePath());
      if (url == null || !mounted) return;
      widget.onChanged('$url?v=${DateTime.now().millisecondsSinceEpoch}');
      AppSnackbar.success(context, context.s.restaurant.photoUploaded);
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.s.restaurant;
    final hasPhoto = widget.url != null && widget.url!.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs + 2, left: 2),
          child: Text(widget.label, style: context.text.label),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: p.border),
              ),
              child: AppNetworkImage(
                url: widget.url,
                width: widget.previewSize,
                height: widget.previewSize,
                fallbackIcon: widget.fallbackIcon,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                semanticLabel: hasPhoto ? widget.label : null,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.helper, style: context.text.caption),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      AppButton(
                        label: hasPhoto ? s.changePhoto : s.uploadPhoto,
                        leadingIcon: Icons.photo_camera_outlined,
                        variant: AppButtonVariant.tonal,
                        size: AppButtonSize.small,
                        expand: false,
                        isLoading: _uploading,
                        onPressed: _upload,
                      ),
                      if (hasPhoto && !_uploading)
                        AppButton(
                          label: s.removePhoto,
                          variant: AppButtonVariant.text,
                          size: AppButtonSize.small,
                          expand: false,
                          onPressed: () => widget.onChanged(null),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
