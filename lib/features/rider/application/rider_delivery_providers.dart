import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../main.dart';
import '../../orders/application/order_provider.dart';
import '../data/supabase/supabase_rider_delivery_repository.dart';
import '../domain/entities/delivery_info.dart';
import '../domain/repositories/rider_delivery_repository.dart';

part 'rider_delivery_providers.g.dart';

@riverpod
RiderDeliveryRepository riderDeliveryRepository(Ref ref) =>
    SupabaseRiderDeliveryRepository(supabase);

@riverpod
Future<Map<String, DeliveryInfo>> availableDeliveryInfo(Ref ref) async {
  final orders = await ref.watch(availableOrdersProvider.future);
  return ref
      .watch(riderDeliveryRepositoryProvider)
      .fetchDeliveryInfo(orders.map((o) => o.id).toList());
}

/// Payment method + pickup details for the rider's current delivery.
@riverpod
Future<DeliveryInfo?> activeDeliveryInfo(Ref ref, String riderId) async {
  final order = await ref.watch(riderActiveOrderProvider(riderId).future);
  if (order == null) return null;
  final info = await ref
      .watch(riderDeliveryRepositoryProvider)
      .fetchDeliveryInfo([order.id]);
  return info[order.id];
}
