import 'package:flutter/widgets.dart';
import 'strings/account_strings.dart';
import 'strings/admin_strings.dart';
import 'strings/auth_strings.dart';
import 'strings/common_strings.dart';
import 'strings/customer_strings.dart';
import 'strings/orders_strings.dart';
import 'strings/restaurant_strings.dart';
import 'strings/rider_strings.dart';

class S {
  S._(this.isNe)
      : common = CommonStrings(isNe),
        auth = AuthStrings(isNe),
        customer = CustomerStrings(isNe),
        orders = OrderStrings(isNe),
        account = AccountStrings(isNe),
        restaurant = RestaurantStrings(isNe),
        rider = RiderStrings(isNe),
        admin = AdminStrings(isNe);

  final bool isNe;
  final CommonStrings common;
  final AuthStrings auth;
  final CustomerStrings customer;
  final OrderStrings orders;
  final AccountStrings account;
  final RestaurantStrings restaurant;
  final RiderStrings rider;
  final AdminStrings admin;

  static final S en = S._(false);
  static final S ne = S._(true);

  static S of(BuildContext context) =>
      Localizations.maybeLocaleOf(context)?.languageCode == 'ne' ? ne : en;
}

extension SX on BuildContext {
  S get s => S.of(this);
}
