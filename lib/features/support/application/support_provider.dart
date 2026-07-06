import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../main.dart';
import '../domain/models/ticket_model.dart';
import '../domain/models/ticket_reply_model.dart';

part 'support_provider.g.dart';

/// A customer/restaurant/rider's own tickets (support_tickets has no
/// realtime publication, so this is a plain future — screens invalidate
/// it after creating a ticket).
@Riverpod(keepAlive: true)
Future<List<TicketModel>> ownTickets(Ref ref, String userId) async {
  final data = await supabase
      .from('support_tickets')
      .select()
      .eq('customer_id', userId)
      .order('created_at', ascending: false);
  return (data as List)
      .map((m) => TicketModel.fromMap(m as Map<String, dynamic>))
      .toList();
}

/// Admin: every ticket on the platform, most recent first.
@Riverpod(keepAlive: true)
Future<List<TicketModel>> allTickets(Ref ref) async {
  final data = await supabase
      .from('support_tickets')
      .select('*, profiles!customer_id(full_name)')
      .order('created_at', ascending: false);
  return (data as List)
      .map((m) => TicketModel.fromMap(m as Map<String, dynamic>))
      .toList();
}

/// Replies for one ticket, oldest first (conversation order).
@Riverpod(keepAlive: true)
Future<List<TicketReplyModel>> ticketReplies(Ref ref, String ticketId) async {
  final data = await supabase
      .from('support_replies')
      .select('*, profiles!actor_id(full_name)')
      .eq('ticket_id', ticketId)
      .order('created_at', ascending: true);
  return (data as List)
      .map((m) => TicketReplyModel.fromMap(m as Map<String, dynamic>))
      .toList();
}

@Riverpod(keepAlive: true)
class SupportActions extends _$SupportActions {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<bool> createTicket({
    required String customerId,
    required String subject,
    required String message,
    String? orderId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await supabase.from('support_tickets').insert({
        'customer_id': customerId,
        'subject': subject,
        'message': message,
        'order_id': orderId,
      });
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> reply({
    required String ticketId,
    required String actorId,
    required String message,
  }) async {
    state = const AsyncValue.loading();
    try {
      await supabase.from('support_replies').insert({
        'ticket_id': ticketId,
        'actor_id': actorId,
        'message': message,
      });
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateStatus(String ticketId, TicketStatus status) async {
    state = const AsyncValue.loading();
    try {
      await supabase.from('support_tickets').update({
        'status': status.dbValue,
        if (status == TicketStatus.resolved || status == TicketStatus.closed)
          'resolved_at': DateTime.now().toIso8601String(),
      }).eq('id', ticketId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
