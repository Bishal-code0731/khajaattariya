import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../main.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/async_value_view.dart';
import '../../../core/utils/image_upload.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/shimmer_loader.dart';

// Fetch menu items for a restaurant (admin/owner view — includes unavailable)
final ownerMenuItemsProvider =
FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, restaurantId) async {
      final data = await supabase
          .from('menu_items')
          .select()
          .eq('restaurant_id', restaurantId)
          .order('sort_order');
      return List<Map<String, dynamic>>.from(data as List);
    });

class MenuManagementScreen extends ConsumerStatefulWidget {
  final String restaurantId;
  final String restaurantName;

  const MenuManagementScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  ConsumerState<MenuManagementScreen> createState() =>
      _MenuManagementScreenState();
}

class _MenuManagementScreenState extends ConsumerState<MenuManagementScreen> {
  // Tracks which item rows have an update/delete in flight so taps on
  // that specific row are ignored until it resolves — other rows stay
  // fully interactive.
  final _busyItemIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final itemsAsync =
    ref.watch(ownerMenuItemsProvider(widget.restaurantId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Menu — ${widget.restaurantName}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showItemSheet(context, null),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Item',
            style: TextStyle(color: Colors.white)),
      ),
      body: AsyncValueView(
        value: itemsAsync,
        loading: () => const AppShimmerCardList(count: 5, itemHeight: 64),
        errorMessage: 'Could not load menu',
        onRetry: () => ref.invalidate(ownerMenuItemsProvider(widget.restaurantId)),
        data: (items) => items.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.restaurant_menu_outlined,
                  size: 64, color: AppColors.textHint),
              const SizedBox(height: AppSpacing.md),
              Text('No menu items yet',
                  style: AppTypography.headingSmall),
              const SizedBox(height: AppSpacing.sm),
              Text('Tap + to add your first item',
                  style: AppTypography.bodyMedium),
            ],
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.only(
            top: AppSpacing.sm,
            bottom: 100, // space for FAB
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final id = items[index]['id'] as String;
            return _MenuItemCard(
              item: items[index],
              isBusy: _busyItemIds.contains(id),
              onEdit: () => _showItemSheet(context, items[index]),
              onDelete: () => _deleteItem(id),
              onToggleAvailable: () => _toggleAvailable(
                id,
                items[index]['is_available'] as bool,
              ),
            );
          },
        ),
      ),
    );
  }

  void _showItemSheet(
      BuildContext context, Map<String, dynamic>? existingItem) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MenuItemForm(
        restaurantId: widget.restaurantId,
        existingItem: existingItem,
        onSaved: () {
          ref.invalidate(ownerMenuItemsProvider(widget.restaurantId));
        },
      ),
    );
  }

  Future<void> _deleteItem(String itemId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete item?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true || _busyItemIds.contains(itemId)) return;
    setState(() => _busyItemIds.add(itemId));
    try {
      final deleted = await supabase.from('menu_items').delete().eq('id', itemId).select('id');
      if (deleted.isEmpty) {
        throw Exception('Could not delete item — it may already be removed.');
      }
      ref.invalidate(ownerMenuItemsProvider(widget.restaurantId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to delete: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _busyItemIds.remove(itemId));
    }
  }

  Future<void> _toggleAvailable(String itemId, bool current) async {
    if (_busyItemIds.contains(itemId)) return;
    setState(() => _busyItemIds.add(itemId));
    try {
      final updated = await supabase
          .from('menu_items')
          .update({'is_available': !current}).eq('id', itemId).select('id');
      if (updated.isEmpty) {
        throw Exception('Could not update item. Please try again.');
      }
      ref.invalidate(ownerMenuItemsProvider(widget.restaurantId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _busyItemIds.remove(itemId));
    }
  }
}

class _MenuItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleAvailable;

  const _MenuItemCard({
    required this.item,
    required this.isBusy,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleAvailable,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = item['is_available'] as bool? ?? true;
    final isVeg = item['is_veg'] as bool? ?? false;

    return GlassCard(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.xs,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppSpacing.radiusLg,
      child: Row(
        children: [
          // Veg indicator
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color: isVeg ? AppColors.success : AppColors.error,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isVeg ? AppColors.success : AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] as String? ?? '',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isAvailable
                        ? null
                        : AppColors.textHint,
                    decoration: isAvailable
                        ? null
                        : TextDecoration.lineThrough,
                  ),
                ),
                Text(
                  'Rs. ${(item['price'] as num?)?.toInt() ?? 0}',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
          // Available toggle
          if (isBusy)
            const SizedBox(width: 16, height: 16, child: AppLoader(size: 16))
          else
            GestureDetector(
              onTap: onToggleAvailable,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: isAvailable
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius:
                  BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  isAvailable ? 'Available' : 'Hidden',
                  style: AppTypography.labelSmall.copyWith(
                    color:
                    isAvailable ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
            ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            onPressed: isBusy ? null : onEdit,
            icon: const Icon(Icons.edit_outlined,
                size: 18, color: AppColors.textSecondary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            onPressed: isBusy ? null : onDelete,
            icon: const Icon(Icons.delete_outline,
                size: 18, color: AppColors.error),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _MenuItemForm extends ConsumerStatefulWidget {
  final String restaurantId;
  final Map<String, dynamic>? existingItem;
  final VoidCallback onSaved;

  const _MenuItemForm({
    required this.restaurantId,
    required this.existingItem,
    required this.onSaved,
  });

  @override
  ConsumerState<_MenuItemForm> createState() => _MenuItemFormState();
}

class _MenuItemFormState extends ConsumerState<_MenuItemForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _imageController;
  late TextEditingController _offerController;
  bool _isVeg = false;
  bool _isLoading = false;
  bool _isUploadingImage = false;

  bool get _isEditing => widget.existingItem != null;

  static String _formatPrice(double price) {
    return price == price.truncateToDouble()
        ? price.toInt().toString()
        : price.toStringAsFixed(2);
  }

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    _nameController =
        TextEditingController(text: item?['name'] as String? ?? '');
    _priceController = TextEditingController(
        text: item != null
            // Preserve decimals (e.g. 149.50) — .toInt() used to silently
            // truncate the paisa on every edit of an existing item.
            ? _formatPrice((item['price'] as num).toDouble())
            : '');
    _imageController =
        TextEditingController(text: item?['image_url'] as String? ?? '');
    _offerController =
        TextEditingController(text: item?['offer'] as String? ?? '');
    _isVeg = item?['is_veg'] as bool? ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _imageController.dispose();
    _offerController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final data = {
        'restaurant_id': widget.restaurantId,
        'name': _nameController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'image_url': _imageController.text.trim().isEmpty
            ? null
            : _imageController.text.trim(),
        'offer': _offerController.text.trim().isEmpty
            ? null
            : _offerController.text.trim(),
        'is_veg': _isVeg,
      };

      if (_isEditing) {
        // Don't force is_available back to true — an owner who hid this
        // item shouldn't have it silently re-listed just from tweaking
        // the name/price/image.
        await supabase
            .from('menu_items')
            .update(data)
            .eq('id', widget.existingItem!['id'] as String);
      } else {
        await supabase.from('menu_items').insert({...data, 'is_available': true});
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    if (_isUploadingImage) return;
    setState(() => _isUploadingImage = true);
    try {
      final path = 'menu-items/${widget.restaurantId}/${DateTime.now().microsecondsSinceEpoch}.jpg';
      final url = await ImageUpload.pickCompressAndUpload(
        supabase: supabase,
        bucket: 'restaurant-media',
        path: path,
        maxDimension: 800,
      );
      if (url != null) _imageController.text = url;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not upload photo: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  _isEditing ? 'Edit Item' : 'Add Menu Item',
                  style: AppTypography.headingSmall,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Item Name',
                  hint: 'e.g. Steam Momo',
                  controller: _nameController,
                  prefixIcon: Icons.fastfood_outlined,
                  validator: (v) => Validators.name(v, field: 'Item name'),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Price (Rs.)',
                  hint: '120',
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.payments_outlined,
                  validator: Validators.price,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Image URL (optional)',
                  hint: 'https://... or upload a photo below',
                  controller: _imageController,
                  prefixIcon: Icons.image_outlined,
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                  icon: _isUploadingImage
                      ? const AppLoader.button(color: AppColors.primary)
                      : const Icon(Icons.upload_rounded, size: 18),
                  label: Text(_isUploadingImage ? 'Uploading…' : 'Upload Photo'),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Offer tag (optional)',
                  hint: 'e.g. Bestseller, 10% off',
                  controller: _offerController,
                  prefixIcon: Icons.local_offer_outlined,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Switch(
                      value: _isVeg,
                      onChanged: (v) => setState(() => _isVeg = v),
                      activeColor: AppColors.success,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      _isVeg ? 'Vegetarian' : 'Non-Vegetarian',
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: _isEditing ? 'Save Changes' : 'Add Item',
                  isLoading: _isLoading,
                  onPressed: _save,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}