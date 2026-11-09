import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../main.dart';
import '../../payments/application/coupon_provider.dart';
import '../../payments/application/payment_provider.dart';
import '../../payments/application/refund_provider.dart';
import '../../rider/application/rider_provider.dart';
import '../../support/application/support_provider.dart';
import '../../support/domain/models/ticket_model.dart';
import '../domain/admin_models.dart';
import 'admin_providers.dart';
import 'admin_queries.dart';

/// Thrown when an update matched no row (RLS refused it or the row is gone).
class AdminUpdateRejected implements Exception {
  const AdminUpdateRejected();
}

/// Every write the admin console makes.
class AdminActions {
  AdminActions(this._ref);
  final Ref _ref;

  String get _adminId {
    final id = supabase.auth.currentUser?.id;
    if (id == null) throw StateError('Not signed in');
    return id;
  }

  Future<void> _audit(String action, String table, String targetId,
      [Map<String, dynamic>? data]) async {
    await supabase.from('audit_logs').insert({
      'actor_id': _adminId,
      'action': action,
      'target_table': table,
      'target_id': targetId,
      'new_data': data,
    });
    _ref.invalidate(adminAuditProvider);
  }

  void _ensure(List<dynamic> updated) {
    if (updated.isEmpty) throw const AdminUpdateRejected();
  }

  Future<void> _delegate(Future<bool> Function() call,
      ProviderListenable<AsyncValue<void>> state) async {
    final ok = await call();
    if (!ok) throw _ref.read(state).error ?? const AdminUpdateRejected();
  }

  // Users
  Future<void> setUserActive(String userId, bool active) async {
    if (userId == _adminId) throw const AdminUpdateRejected();
    final updated = await supabase
        .from('profiles')
        .update({'is_active': active})
        .eq('id', userId)
        .select('id');
    _ensure(updated);
    await _audit(active ? 'unban_user' : 'ban_user', 'profiles', userId,
        {'is_active': active});
    _ref.invalidate(adminUsersProvider);
  }

  // Restaurants
  Future<void> approveRestaurant(String id) async {
    final n = _ref.read(restaurantApprovalNotifierProvider.notifier);
    await _delegate(() => n.approve(id), restaurantApprovalNotifierProvider);
    _afterRestaurantChange();
  }

  Future<void> rejectRestaurant(String id, String note) async {
    final n = _ref.read(restaurantApprovalNotifierProvider.notifier);
    await _delegate(
        () => n.reject(id, note), restaurantApprovalNotifierProvider);
    _afterRestaurantChange();
  }

  Future<void> setRestaurantActive(String id, bool active) async {
    final updated = await supabase
        .from('restaurants')
        .update({'is_active': active})
        .eq('id', id)
        .select('id');
    _ensure(updated);
    await _audit(active ? 'activate_restaurant' : 'deactivate_restaurant',
        'restaurants', id, {'is_active': active});
    _afterRestaurantChange();
  }

  Future<void> setRestaurantFeatured(String id, bool featured) async {
    final updated = await supabase
        .from('restaurants')
        .update({'is_featured': featured})
        .eq('id', id)
        .select('id');
    _ensure(updated);
    await _audit(featured ? 'feature_restaurant' : 'unfeature_restaurant',
        'restaurants', id, {'is_featured': featured});
    _afterRestaurantChange();
  }

  void _afterRestaurantChange() {
    _ref.invalidate(adminRestaurantsProvider);
    _ref.invalidate(adminOverviewProvider);
    _ref.invalidate(adminAuditProvider);
  }

  // Riders
  Future<void> approveRider(String riderId) async {
    final n = _ref.read(riderApprovalNotifierProvider.notifier);
    await _delegate(
        () => n.approveRider(riderId), riderApprovalNotifierProvider);
    await _audit('approve_rider', 'riders', riderId, {'is_approved': true});
    _ref.invalidate(allRidersProvider);
    _ref.invalidate(adminOverviewProvider);
  }

  Future<void> rejectRider(String riderId, String note) async {
    final n = _ref.read(riderApprovalNotifierProvider.notifier);
    await _delegate(
        () => n.rejectRider(riderId, note), riderApprovalNotifierProvider);
    await _audit('reject_rider', 'riders', riderId,
        {'is_approved': false, 'note': note});
    _ref.invalidate(allRidersProvider);
    _ref.invalidate(adminOverviewProvider);
  }

  // Coupons
  /// Creates a coupon, or updates [couponId] when given.
  Future<void> saveCoupon(CouponDraft draft, {String? couponId}) async {
    final row = draft.toRow();
    if (couponId == null) {
      final created = await supabase
          .from('coupons')
          .insert({...row, 'is_active': true})
          .select('id')
          .single();
      await _audit('create_coupon', 'coupons', created['id'] as String,
          {'code': row['code']});
    } else {
      final updated = await supabase
          .from('coupons')
          .update(row)
          .eq('id', couponId)
          .select('id');
      _ensure(updated);
      await _audit('update_coupon', 'coupons', couponId, {'code': row['code']});
    }
    _ref.invalidate(adminCouponsProvider);
    _ref.invalidate(allCouponsProvider);
  }

  Future<void> setCouponActive(String couponId, bool active) async {
    final updated = await supabase
        .from('coupons')
        .update({'is_active': active})
        .eq('id', couponId)
        .select('id');
    _ensure(updated);
    await _audit(active ? 'enable_coupon' : 'disable_coupon', 'coupons',
        couponId, {'is_active': active});
    _ref.invalidate(adminCouponsProvider);
    _ref.invalidate(allCouponsProvider);
  }

  // Support
  Future<void> replyToTicket(TicketModel ticket, String message,
      {bool internal = false}) async {
    await supabase.from('support_replies').insert({
      'ticket_id': ticket.id,
      'actor_id': _adminId,
      'message': message,
      'is_internal': internal,
    });
    await _audit(
        'reply_ticket', 'support_tickets', ticket.id, {'internal': internal});
    // A public reply on a new ticket means someone is on it.
    if (!internal && ticket.status == TicketStatus.open) {
      await setTicketStatus(ticket.id, TicketStatus.inProgress);
    }
    _ref.invalidate(ticketRepliesProvider(ticket.id));
  }

  Future<void> setTicketStatus(String ticketId, TicketStatus status) async {
    final n = _ref.read(supportActionsProvider.notifier);
    await _delegate(
        () => n.updateStatus(ticketId, status), supportActionsProvider);
    await _audit('update_ticket_status', 'support_tickets', ticketId,
        {'status': status.dbValue});
    _ref.invalidate(allTicketsProvider);
    _ref.invalidate(adminOverviewProvider);
  }

  // Refunds
  Future<void> decideRefund(String refundId, {required bool approve}) async {
    final status = approve ? 'approved' : 'rejected';
    final n = _ref.read(refundNotifierProvider.notifier);
    await _delegate(
        () => n.updateStatus(refundId, status), refundNotifierProvider);
    await _audit(approve ? 'approve_refund' : 'reject_refund', 'refunds',
        refundId, {'status': status});
    _ref.invalidate(adminRefundsProvider);
    _ref.invalidate(allRefundsProvider);
    _ref.invalidate(adminOverviewProvider);
  }

  // Rider cash
  /// Confirms (cash counted and received) or rejects a pending settlement.
  Future<void> decideSettlement(String entryId, {required bool confirm}) async {
    final status = confirm ? 'confirmed' : 'rejected';
    final updated = await supabase
        .from('rider_cash_ledger')
        .update({
          'status': status,
          'confirmed_by': _adminId,
          'confirmed_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', entryId)
        .eq('status', 'pending')
        .select('id');
    _ensure(updated);
    await _audit(confirm ? 'confirm_settlement' : 'reject_settlement',
        'rider_cash_ledger', entryId, {'status': status});
    _ref.invalidate(adminSettlementsProvider);
    _ref.invalidate(adminRiderCashProvider);
    _ref.invalidate(adminOverviewProvider);
  }

  // Settings
  /// Saves only the changed keys; the settings notifier writes one audit row per key.
  Future<void> saveSettings(Map<String, String> changed) async {
    final n = _ref.read(platformSettingsNotifierProvider.notifier);
    for (final entry in changed.entries) {
      await _delegate(() => n.updateSetting(entry.key, entry.value),
          platformSettingsNotifierProvider);
    }
    _ref.invalidate(platformSettingsProvider);
    _ref.invalidate(adminAuditProvider);
  }
}

final adminActionsProvider = Provider<AdminActions>((ref) => AdminActions(ref));
