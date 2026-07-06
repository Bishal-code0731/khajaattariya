import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../application/tracking_provider.dart';

class OrderTrackingScreen extends ConsumerWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final positionAsync = ref.watch(orderPositionProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Your Order'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: positionAsync.when(
        loading: () => const AppLoader.fullscreen(),
        error: (_, __) => const AppEmptyState(
          icon: Icons.location_off_outlined,
          title: 'Could not load rider location',
        ),
        data: (position) {
          if (position == null) {
            return const AppEmptyState(
              icon: Icons.motorcycle_outlined,
              title: 'Waiting for your rider',
              subtitle: 'The map will update once your rider is on the way.',
            );
          }
          final point = LatLng(position.lat, position.lng);
          return Stack(
            children: [
              FlutterMap(
                options: MapOptions(initialCenter: point, initialZoom: 15),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.khajaattariya.khajaattariya',
                  ),
                  MarkerLayer(markers: [
                    Marker(
                      point: point,
                      width: 44,
                      height: 44,
                      child: const Icon(Icons.delivery_dining_rounded,
                          color: AppColors.primary, size: 36),
                    ),
                  ]),
                ],
              ),
              Positioned(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.md,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12)],
                  ),
                  child: Row(children: [
                    const Icon(Icons.access_time_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Last updated ${_timeAgo(position.recordedAt)}', style: AppTypography.bodySmall),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}
