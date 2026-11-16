import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_top_bar.dart';
import '../../../../shared/widgets/shimmer_loader.dart';
import '../../application/menu_management_provider.dart';
import '../../application/restaurant_media_upload.dart';
import '../../domain/models/owner_menu_item.dart';
import 'photo_upload_field.dart';
import 'veg_mark.dart';
import '../../../../shared/widgets/busy_overlay.dart';

/// Opens the add / edit dish form full screen.
Future<bool> showMenuItemForm(BuildContext context,
    {required String restaurantId, OwnerMenuItem? item}) async {
  final saved = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => MenuItemFormPage(restaurantId: restaurantId, item: item),
    ),
  );
  return saved ?? false;
}

class MenuItemFormPage extends ConsumerStatefulWidget {
  const MenuItemFormPage({super.key, required this.restaurantId, this.item});

  final String restaurantId;
  final OwnerMenuItem? item;

  @override
  ConsumerState<MenuItemFormPage> createState() => _MenuItemFormPageState();
}

class _MenuItemFormPageState extends ConsumerState<MenuItemFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _offer;
  String? _imageUrl;
  String? _categoryId;
  bool _isVeg = false;
  bool _saving = false;

  bool get _editing => widget.item != null;

  static String _priceText(double price) => price == price.truncateToDouble()
      ? price.toInt().toString()
      : price.toStringAsFixed(2);

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _name = TextEditingController(text: item?.name ?? '');
    _description = TextEditingController(text: item?.description ?? '');
    // Keep decimals (149.50) so editing never truncates a price.
    _price =
        TextEditingController(text: item == null ? '' : _priceText(item.price));
    _offer = TextEditingController(text: item?.offer ?? '');
    _imageUrl = item?.imageUrl;
    _categoryId = item?.categoryId;
    _isVeg = item?.isVeg ?? false;
  }

  @override
  void dispose() {
    for (final c in [_name, _description, _price, _offer]) {
      c.dispose();
    }
    super.dispose();
  }

  static String? _orNull(String v) => v.trim().isEmpty ? null : v.trim();

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final input = MenuItemInput(
      name: _name.text.trim(),
      description: _orNull(_description.text),
      price: double.parse(_price.text.trim()),
      imageUrl: _imageUrl,
      offer: _orNull(_offer.text),
      categoryId: _categoryId,
      isVeg: _isVeg,
    );
    final actions = ref.read(menuItemActionsProvider);
    try {
      if (_editing) {
        await actions.update(widget.item!.id, input);
      } else {
        await actions.create(widget.restaurantId, input);
      }
      if (!mounted) return;
      final s = context.s.restaurant;
      AppSnackbar.success(context, _editing ? s.dishUpdated : s.dishAdded);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        AppSnackbar.error(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
      BusyOverlay(busy: _saving, child: _buildBusyContent(context));

  Widget _buildBusyContent(BuildContext context) {
    final s = context.s.restaurant;
    final c = context.s.common;
    final v = context.validators;
    const gap = SizedBox(height: AppSpacing.lg);

    return Scaffold(
      appBar: AppTopBar(title: _editing ? s.editDishTitle : s.newDishTitle),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal,
              AppSpacing.lg, AppSpacing.screenHorizontal, AppSpacing.xxl),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PhotoUploadField(
                    label: s.dishPhoto,
                    helper: s.dishPhotoHelper,
                    url: _imageUrl,
                    previewSize: 112,
                    fallbackIcon: Icons.ramen_dining_outlined,
                    storagePath: () =>
                        RestaurantMediaPaths.menuItem(widget.restaurantId),
                    onChanged: (url) => setState(() => _imageUrl = url),
                  ),
                  gap,
                  AppTextField(
                    label: s.fieldDishName,
                    hint: s.hintDishName,
                    controller: _name,
                    textCapitalization: TextCapitalization.sentences,
                    validator: v.text(s.fieldDishName, min: 1, max: 80),
                  ),
                  gap,
                  AppTextField(
                    label: s.fieldDescription,
                    hint: s.hintDescription,
                    controller: _description,
                    maxLines: 3,
                    minLines: 2,
                    maxLength: 300,
                    textCapitalization: TextCapitalization.sentences,
                    validator: v.text(s.fieldDescriptionShort,
                        max: 300, optional: true),
                  ),
                  gap,
                  AppTextField(
                    label: s.fieldPriceRs,
                    hint: '180',
                    controller: _price,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    prefixIcon: Icons.payments_outlined,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d{0,6}(\.\d{0,2})?'))
                    ],
                    validator: v.price,
                  ),
                  gap,
                  _CategoryPicker(
                    value: _categoryId,
                    onChanged: (id) => setState(() => _categoryId = id),
                  ),
                  gap,
                  _VegSwitch(
                      value: _isVeg,
                      onChanged: (val) => setState(() => _isVeg = val)),
                  gap,
                  AppTextField(
                    label: s.fieldDishOffer,
                    hint: s.hintDishOffer,
                    controller: _offer,
                    prefixIcon: Icons.local_offer_outlined,
                    maxLength: 40,
                    validator:
                        v.text(s.fieldDishOfferShort, max: 40, optional: true),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _BottomBar(
        child: AppButton(
          label: _editing ? c.saveChanges : s.addToMenu,
          isLoading: _saving,
          onPressed: _save,
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.border)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal,
              AppSpacing.md, AppSpacing.screenHorizontal, AppSpacing.md),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560), child: child),
          ),
        ),
      ),
    );
  }
}

class _CategoryPicker extends ConsumerWidget {
  const _CategoryPicker({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s.restaurant;
    final p = context.palette;
    final categoriesAsync = ref.watch(menuCategoriesProvider);

    Widget field;
    if (categoriesAsync.hasValue) {
      final cats = categoriesAsync.value!;
      // A category an admin has since switched off still shows as selected.
      final known = value == null || cats.any((cat) => cat.id == value);
      field = DropdownButtonFormField<String?>(
        initialValue: known ? value : null,
        isExpanded: true,
        decoration: const InputDecoration(
            prefixIcon: Icon(Icons.category_outlined, size: 20)),
        dropdownColor: p.surface,
        style: context.text.bodyLarge,
        items: [
          DropdownMenuItem<String?>(value: null, child: Text(s.noCategory)),
          for (final cat in cats)
            DropdownMenuItem<String?>(
              value: cat.id,
              child:
                  Text(cat.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: onChanged,
      );
    } else if (categoriesAsync.hasError) {
      field = Row(
        children: [
          Expanded(
              child: Text(context.s.common.errorTitle,
                  style: context.text.caption)),
          AppButton(
            label: context.s.common.retry,
            variant: AppButtonVariant.text,
            size: AppButtonSize.small,
            expand: false,
            onPressed: () => ref.invalidate(menuCategoriesProvider),
          ),
        ],
      );
    } else {
      field = AppShimmer(
          height: 52, borderRadius: BorderRadius.circular(AppSpacing.radiusMd));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs + 2, left: 2),
          child: Text(s.fieldCategory, style: context.text.label),
        ),
        field,
      ],
    );
  }
}

class _VegSwitch extends StatelessWidget {
  const _VegSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.s.restaurant;
    return MergeSemantics(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: p.border),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          color: p.surface,
        ),
        child: SwitchListTile(
          value: value,
          onChanged: onChanged,
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
          secondary: VegMark(isVeg: value, size: 18),
          title: Text(s.fieldVeg, style: context.text.label),
          subtitle: Text(s.vegHelper, style: context.text.caption),
        ),
      ),
    );
  }
}
