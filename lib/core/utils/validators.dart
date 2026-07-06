/// Central form-field validators. Every form in the app should validate
/// through these instead of ad-hoc `v.contains('@')`-style checks, so
/// the rules (and their error copy) stay consistent everywhere and a
/// tightened rule only needs to change in one place.
class Validators {
  Validators._();

  static final RegExp _emailPattern =
      RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');

  // Nepali mobile numbers: optional +977 country code, then a 10-digit
  // number starting 97/98 (the ranges actually issued to subscribers).
  static final RegExp _phonePattern = RegExp(r'^(?:\+977[- ]?)?9[78]\d{8}$');

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? email(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Email is required';
    if (!_emailPattern.hasMatch(trimmed)) return 'Enter a valid email address';
    return null;
  }

  /// Production-grade but not paranoid: length + at least one letter and
  /// one digit. Long random passphrases still pass; "123456" doesn't.
  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Password must be at least 8 characters';
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(v);
    final hasDigit = RegExp(r'\d').hasMatch(v);
    if (!hasLetter || !hasDigit) {
      return 'Password must contain both letters and numbers';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? phone(String? value, {bool optional = false}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return optional ? null : 'Phone number is required';
    if (!_phonePattern.hasMatch(trimmed.replaceAll(' ', ''))) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  static String? address(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Address is required';
    if (trimmed.length < 8) return 'Enter a more complete address';
    return null;
  }

  static String? name(String? value, {String field = 'Name'}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return '$field is required';
    if (trimmed.length < 2) return '$field is too short';
    return null;
  }

  static String? price(String? value, {String field = 'Price'}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return '$field is required';
    final parsed = double.tryParse(trimmed);
    if (parsed == null) return 'Enter a valid amount';
    if (parsed <= 0) return '$field must be greater than 0';
    if (parsed > 1000000) return '$field is unrealistically high';
    return null;
  }

  /// Non-negative number, zero allowed (e.g. delivery fee, min order
  /// amount, discount value) — unlike [price] which must be > 0.
  static String? nonNegativeNumber(String? value, {String field = 'Value'}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return '$field is required';
    final parsed = double.tryParse(trimmed);
    if (parsed == null) return 'Enter a valid number';
    if (parsed < 0) return '$field cannot be negative';
    return null;
  }

  static String? restaurantName(String? value) => name(value, field: 'Restaurant name');

  static String? cuisineType(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Cuisine type is required';
    return null;
  }

  /// Combines multiple validators, returning the first failure — use for
  /// fields with more than one independent rule (e.g. a coupon code that
  /// must be both non-empty and uppercase-alnum).
  static String? Function(String?) combine(List<String? Function(String?)> validators) {
    return (value) {
      for (final v in validators) {
        final result = v(value);
        if (result != null) return result;
      }
      return null;
    };
  }
}
