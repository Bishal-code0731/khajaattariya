import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../router/route_names.dart';

/// Single source of truth for the four account types in the app.
/// Every place that used to compare against raw strings like
/// `'admin'`/`'rider'`/`'restaurant'`/`'customer'` should use this
/// enum instead, so the mapping to routes/colors/labels only lives
/// in one place.
enum UserRole {
  customer,
  restaurant,
  rider,
  admin;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => UserRole.customer,
    );
  }

  String get label {
    switch (this) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.restaurant:
        return 'Restaurant';
      case UserRole.rider:
        return 'Rider';
      case UserRole.admin:
        return 'Admin';
    }
  }

  Color get color {
    switch (this) {
      case UserRole.customer:
        return AppColors.customerColor;
      case UserRole.restaurant:
        return AppColors.restaurantColor;
      case UserRole.rider:
        return AppColors.riderColor;
      case UserRole.admin:
        return AppColors.adminColor;
    }
  }

  /// Where this role lands after login/signup/splash.
  String get homeRoute {
    switch (this) {
      case UserRole.customer:
        return RouteNames.home;
      case UserRole.restaurant:
        return RouteNames.restaurantDashboard;
      case UserRole.rider:
        return RouteNames.riderDashboard;
      case UserRole.admin:
        return RouteNames.adminDashboard;
    }
  }
}
