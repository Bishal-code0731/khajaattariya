import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';

class OrderTimelineEvent {
  final String id;
  final String orderId;
  final String status;
  final String? note;
  final String? actorId;
  final DateTime createdAt;

  const OrderTimelineEvent({
    required this.id, required this.orderId, required this.status,
    this.note, this.actorId, required this.createdAt,
  });

  factory OrderTimelineEvent.fromMap(Map<String, dynamic> map) {
    return OrderTimelineEvent(
      id: map['id'] as String,
      orderId: map['order_id'] as String,
      status: map['status'] as String,
      note: map['note'] as String?,
      actorId: map['actor_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String get statusLabel {
    switch (status) {
      case 'pending':   return 'Order Placed';
      case 'confirmed': return 'Confirmed by Restaurant';
      case 'preparing': return 'Being Prepared';
      case 'ready':     return 'Ready for Pickup';
      case 'picked_up': return 'Rider Picked Up';
      case 'delivered': return 'Delivered';
      case 'cancelled': return 'Cancelled';
      default:          return status.replaceAll('_', ' ');
    }
  }
}

final orderTimelineProvider =
StreamProvider.family<List<OrderTimelineEvent>, String>((ref, orderId) {
  return supabase
      .from('order_timeline')
      .stream(primaryKey: ['id'])
      .eq('order_id', orderId)
      .order('created_at', ascending: true)
      .map((data) => data
      .map((m) => OrderTimelineEvent.fromMap(m as Map<String, dynamic>))
      .toList());
});