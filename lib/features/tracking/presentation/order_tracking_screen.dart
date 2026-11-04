import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/l10n/s.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/error_state_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../orders/application/order_provider.dart';
import '../../orders/domain/models/order_model.dart';
import '../application/tracking_provider.dart';
import '../domain/models/delivery_position_model.dart';
import 'widgets/tracking_panel.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  final _map = MapController();
  bool _mapReady = false;

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  void _focusRider(DeliveryPositionModel position) {
    if (!_mapReady) return;
    _map.move(LatLng(position.lat, position.lng), _map.camera.zoom);
  }

  @override
  Widget build(BuildContext context) {
    final o = context.s.orders;
    final positionAsync = ref.watch(orderPositionProvider(widget.orderId));
    final order = ref.watch(orderStreamProvider(widget.orderId)).valueOrNull;

    // Follow the rider as new positions arrive.
    ref.listen(orderPositionProvider(widget.orderId), (prev, next) {
      final pos = next.valueOrNull;
      if (pos != null && pos.recordedAt != prev?.valueOrNull?.recordedAt) {
        _focusRider(pos);
      }
    });

    return Scaffold(
      appBar: AppTopBar(
        title: o.trackTitle,
        subtitle: AppFormat.orderCode(widget.orderId),
      ),
      body: positionAsync.when(
        skipLoadingOnRefresh: true,
        loading: () => const AppLoader.fullscreen(),
        error: (e, _) => AppErrorState(
          error: e,
          icon: Icons.location_off_outlined,
          onRetry: () => ref.invalidate(orderPositionProvider(widget.orderId)),
        ),
        data: (position) => _body(context, order, position),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    OrderModel? order,
    DeliveryPositionModel? position,
  ) {
    final p = context.palette;
    final o = context.s.orders;
    final rider = position == null ? null : LatLng(position.lat, position.lng);
    final restaurant =
        order?.restaurantLat != null && order?.restaurantLng != null
            ? LatLng(order!.restaurantLat!, order.restaurantLng!)
            : null;
    final points = [
      if (rider != null) rider,
      if (restaurant != null) restaurant
    ];

    final panel = Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TrackingPanel(order: order, position: position),
          ),
        ),
      ),
    );

    // Nothing to put on a map yet.
    if (points.isEmpty) {
      return Stack(
        children: [
          Positioned.fill(
            bottom: 260,
            child: AppEmptyState(
              icon: Icons.delivery_dining_outlined,
              title: o.waitingForRiderTitle,
              subtitle: o.waitingForRiderBody,
            ),
          ),
          panel,
        ],
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: points.first,
            initialZoom: 15,
            initialCameraFit: points.length > 1
                ? CameraFit.coordinates(
                    coordinates: points,
                    padding: const EdgeInsets.fromLTRB(48, 48, 48, 300),
                    maxZoom: 17,
                  )
                : null,
            onMapReady: () => _mapReady = true,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.khajaattariya.khajaattariya',
            ),
            MarkerLayer(markers: [
              if (restaurant != null)
                Marker(
                  point: restaurant,
                  width: 44,
                  height: 44,
                  child: _Pin(
                    icon: Icons.storefront_rounded,
                    color: p.accent,
                    iconColor: p.onAccent,
                    label: o.restaurantMarker,
                  ),
                ),
              if (rider != null)
                Marker(
                  point: rider,
                  width: 52,
                  height: 52,
                  child: _Pin(
                    icon: Icons.delivery_dining_rounded,
                    color: p.brand,
                    iconColor: p.onBrand,
                    label: o.riderMarker,
                    large: true,
                  ),
                ),
            ]),
            SimpleAttributionWidget(
              source: Text(o.mapAttribution),
              alignment: Alignment.topLeft,
              backgroundColor: p.surface,
            ),
          ],
        ),
        if (position != null)
          Positioned(
            top: AppSpacing.md,
            right: AppSpacing.md,
            child: IconButton.filled(
              tooltip: o.recenter,
              style: IconButton.styleFrom(
                backgroundColor: p.surface,
                foregroundColor: p.brand,
                minimumSize: const Size(48, 48),
                side: BorderSide(color: p.border),
              ),
              onPressed: () => _focusRider(position),
              icon: const Icon(Icons.my_location_rounded),
            ),
          ),
        panel,
      ],
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.label,
    this.large = false,
  });

  final IconData icon;
  final Color color;
  final Color iconColor;
  final String label;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: label,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: p.surface, width: 3),
          boxShadow: AppShadows.card(p.shadow),
        ),
        child: Icon(icon, color: iconColor, size: large ? 28 : 22),
      ),
    );
  }
}
