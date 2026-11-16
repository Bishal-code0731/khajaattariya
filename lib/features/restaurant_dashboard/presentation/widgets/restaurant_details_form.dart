import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/l10n/strings/restaurant_strings.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../application/restaurant_media_upload.dart';
import '../../domain/models/owner_restaurant.dart';
import 'photo_upload_field.dart';
import '../../../../shared/widgets/busy_overlay.dart';

/// Restaurant name, cuisine, address, phone, delivery time, logo and (when editing) the offer line.
class RestaurantDetailsForm extends StatefulWidget {
  const RestaurantDetailsForm({
    super.key,
    required this.ownerId,
    required this.submitLabel,
    required this.onSubmit,
    this.initial,
    this.showOffer = false,
  });

  final String ownerId;
  final String submitLabel;
  final OwnerRestaurant? initial;
  final bool showOffer;

  /// Returns true when saved; the form shows the loading state meanwhile.
  final Future<bool> Function(RestaurantDetailsInput input) onSubmit;

  @override
  State<RestaurantDetailsForm> createState() => _RestaurantDetailsFormState();
}

class _RestaurantDetailsFormState extends State<RestaurantDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _cuisine;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late final TextEditingController _deliveryTime;
  late final TextEditingController _offer;
  String? _imageUrl;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final r = widget.initial;
    _name = TextEditingController(text: r?.name ?? '');
    _cuisine = TextEditingController(text: r?.cuisineType ?? '');
    _address = TextEditingController(text: r?.address ?? '');
    _phone = TextEditingController(text: r?.phone ?? '');
    _deliveryTime = TextEditingController(text: '${r?.deliveryTimeMin ?? 30}');
    _offer = TextEditingController(text: r?.offer ?? '');
    _imageUrl = r?.imageUrl;
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _cuisine,
      _address,
      _phone,
      _deliveryTime,
      _offer
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _cuisineParts => _cuisine.text
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  void _toggleCuisine(String key) {
    final parts = _cuisineParts;
    final idx = parts.indexWhere((p) => p.toLowerCase() == key.toLowerCase());
    if (idx >= 0) {
      parts.removeAt(idx);
    } else {
      parts.add(key);
    }
    setState(() => _cuisine.text = parts.join(', '));
  }

  static String? _nullIfEmpty(String v) => v.trim().isEmpty ? null : v.trim();

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    final input = RestaurantDetailsInput(
      name: _name.text.trim(),
      cuisineType: _cuisineParts.join(', '),
      address: _address.text.trim(),
      phone: _phone.text.trim().replaceAll(RegExp(r'[\s-]'), ''),
      deliveryTimeMin: int.parse(_deliveryTime.text.trim()),
      imageUrl: _imageUrl,
      offer:
          widget.showOffer ? _nullIfEmpty(_offer.text) : widget.initial?.offer,
    );
    await widget.onSubmit(input);
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) =>
      BusyOverlay(busy: _submitting, child: _buildBusyContent(context));

  Widget _buildBusyContent(BuildContext context) {
    final s = context.s.restaurant;
    final c = context.s.common;
    final v = context.validators;
    const gap = SizedBox(height: AppSpacing.lg);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          PhotoUploadField(
            label: s.logoLabel,
            helper: s.photoHelper,
            url: _imageUrl,
            storagePath: () => RestaurantMediaPaths.logo(widget.ownerId),
            onChanged: (url) => setState(() => _imageUrl = url),
          ),
          gap,
          AppTextField(
            label: s.fieldRestaurantName,
            hint: s.hintRestaurantName,
            controller: _name,
            prefixIcon: Icons.storefront_outlined,
            textCapitalization: TextCapitalization.words,
            validator: v.name(s.fieldRestaurantName),
          ),
          gap,
          AppTextField(
            label: s.fieldCuisine,
            hint: s.hintCuisine,
            helper: s.cuisineHelper,
            controller: _cuisine,
            prefixIcon: Icons.restaurant_menu_rounded,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            validator: v.text(s.fieldCuisine, min: 2, max: 60),
          ),
          const SizedBox(height: AppSpacing.sm),
          _CuisineChips(selected: _cuisineParts, onToggle: _toggleCuisine),
          gap,
          AppTextField(
            label: c.fieldAddress,
            hint: s.hintAddress,
            controller: _address,
            prefixIcon: Icons.location_on_outlined,
            maxLines: 2,
            minLines: 1,
            validator: v.address,
          ),
          gap,
          LayoutBuilder(builder: (context, constraints) {
            final phone = AppTextField(
              label: c.fieldPhone,
              hint: '98XXXXXXXX',
              controller: _phone,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
              autofillHints: const [AutofillHints.telephoneNumber],
              validator: v.phone,
            );
            final time = AppTextField(
              label: s.fieldDeliveryTime,
              helper: s.deliveryTimeHelper,
              controller: _deliveryTime,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.timer_outlined,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3)
              ],
              validator: v.integerRange(s.fieldDeliveryTime, 5, 240),
            );
            if (constraints.maxWidth < 520) {
              return Column(children: [phone, gap, time]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: phone),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: time),
              ],
            );
          }),
          if (widget.showOffer) ...[
            gap,
            AppTextField(
              label: s.fieldOffer,
              hint: s.hintOffer,
              helper: s.offerHelper,
              controller: _offer,
              prefixIcon: Icons.local_offer_outlined,
              maxLength: 60,
              validator: v.text(s.offerField, max: 60, optional: true),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: widget.submitLabel,
            isLoading: _submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class _CuisineChips extends StatelessWidget {
  const _CuisineChips({required this.selected, required this.onToggle});

  final List<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final s = context.s.restaurant;
    final p = context.palette;
    final lower = selected.map((e) => e.toLowerCase()).toSet();
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        for (final key in RestaurantStrings.cuisineSuggestions)
          FilterChip(
            label: Text(s.cuisineLabel(key)),
            selected: lower.contains(key.toLowerCase()),
            onSelected: (_) => onToggle(key),
            showCheckmark: true,
            checkmarkColor: p.onBrandSoft,
            selectedColor: p.brandSoft,
            backgroundColor: p.surface,
            side: BorderSide(color: p.border),
            labelStyle: context.text.label,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
          ),
      ],
    );
  }
}
