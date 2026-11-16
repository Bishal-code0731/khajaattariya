import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../main.dart';
import '../../auth/application/auth_provider.dart';
import '../../payments/domain/models/coupon_model.dart';
import '../data/supabase/supabase_offer_repository.dart';
import '../domain/repositories/offer_repository.dart';

part 'offers_provider.g.dart';

/// Binds the offers interface to its Supabase implementation.
@riverpod
OfferRepository offerRepository(Ref ref) => SupabaseOfferRepository(supabase);

/// Coupons for the signed-in customer; empty for guests (coupons need an account).
@riverpod
Future<List<CouponModel>> availableCoupons(Ref ref) async {
  final user = await ref.watch(authStateProvider.future);
  if (user == null) return const [];
  return ref.watch(offerRepositoryProvider).availableCoupons();
}
