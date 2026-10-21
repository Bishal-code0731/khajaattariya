import 'package:flutter/widgets.dart';
import '../l10n/s.dart';
import '../l10n/strings/common_strings.dart';

typedef FieldValidator = String? Function(String? value);

/// Form validation with friendly, translated messages.
class AppValidators {
  const AppValidators(this._c);
  final CommonStrings _c;

  // Accepts multi-part domains (name@mail.co.uk) and plus-addressing.
  static final RegExp _email = RegExp(
      r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$");
  // Nepali mobile: optional +977, then 97/98 and 8 more digits.
  static final RegExp _phone = RegExp(r'^(?:\+?977)?9[678]\d{8}$');
  static final RegExp _time = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

  static String _clean(String? v) => v?.trim() ?? '';

  String? required(String? value, [String? field]) => _clean(value).isEmpty
      ? (field == null ? _c.fieldRequired : _c.required(field))
      : null;

  FieldValidator requiredField(String field) => (v) => required(v, field);

  String? email(String? value) {
    final v = _clean(value);
    if (v.isEmpty) return _c.required(_c.fieldEmail);
    if (v.length > 254 || !_email.hasMatch(v)) return _c.invalidEmail;
    return null;
  }

  String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return _c.required(_c.fieldPassword);
    if (v.length < 8) return _c.passwordTooShort(8);
    if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
      return _c.passwordNeedsLetterAndNumber;
    }
    return null;
  }

  /// Login only checks the field isn't empty (older accounts may have weaker passwords).
  String? loginPassword(String? value) =>
      (value ?? '').isEmpty ? _c.required(_c.fieldPassword) : null;

  FieldValidator confirmPassword(String Function() original) => (v) {
        if ((v ?? '').isEmpty) return _c.required(_c.fieldPassword);
        return v == original() ? null : _c.passwordsDontMatch;
      };

  String? phone(String? value) {
    final v = _clean(value).replaceAll(RegExp(r'[\s-]'), '');
    if (v.isEmpty) return _c.required(_c.fieldPhone);
    return _phone.hasMatch(v) ? null : _c.invalidPhone;
  }

  String? optionalPhone(String? value) =>
      _clean(value).isEmpty ? null : phone(value);

  FieldValidator name([String? field]) => (v) {
        final s = _clean(v);
        final label = field ?? _c.fieldName;
        if (s.isEmpty) return _c.required(label);
        if (s.length < 2) return _c.minLength(label, 2);
        if (s.length > 80) return _c.maxLength(label, 80);
        return null;
      };

  String? address(String? value) {
    final v = _clean(value);
    if (v.isEmpty) return _c.required(_c.fieldAddress);
    if (v.length < 8) return _c.minLength(_c.fieldAddress, 8);
    if (v.length > 250) return _c.maxLength(_c.fieldAddress, 250);
    return null;
  }

  FieldValidator text(String field,
          {int min = 1, int max = 500, bool optional = false}) =>
      (v) {
        final s = _clean(v);
        if (s.isEmpty) return optional ? null : _c.required(field);
        if (s.length < min) return _c.minLength(field, min);
        if (s.length > max) return _c.maxLength(field, max);
        return null;
      };

  String? price(String? value) {
    final v = _clean(value);
    if (v.isEmpty) return _c.required(_c.fieldPrice);
    final n = double.tryParse(v);
    if (n == null) return _c.invalidNumber;
    if (n <= 0) return _c.priceMustBePositive;
    if (n > 100000) return _c.priceTooHigh('100,000');
    return null;
  }

  FieldValidator nonNegative(String field,
          {bool optional = false, double? max}) =>
      (v) {
        final s = _clean(v);
        if (s.isEmpty) return optional ? null : _c.required(field);
        final n = double.tryParse(s);
        if (n == null) return _c.invalidNumber;
        if (n < 0) return _c.mustNotBeNegative;
        if (max != null && n > max) {
          return _c.priceTooHigh(max.toStringAsFixed(0));
        }
        return null;
      };

  FieldValidator integerRange(String field, int min, int max) => (v) {
        final s = _clean(v);
        if (s.isEmpty) return _c.required(field);
        final n = int.tryParse(s);
        if (n == null || n < min || n > max) return _c.invalidNumber;
        return null;
      };

  String? optionalUrl(String? value) {
    final v = _clean(value);
    if (v.isEmpty) return null;
    final uri = Uri.tryParse(v);
    return (uri != null && uri.scheme == 'https' && uri.host.isNotEmpty)
        ? null
        : _c.invalidUrl;
  }

  String? time24(String? value) {
    final v = _clean(value);
    if (v.isEmpty) return _c.fieldRequired;
    return _time.hasMatch(v) ? null : _c.invalidTime;
  }

  /// First failing validator wins.
  static FieldValidator combine(List<FieldValidator> validators) => (value) {
        for (final v in validators) {
          final r = v(value);
          if (r != null) return r;
        }
        return null;
      };
}

extension AppValidatorsX on BuildContext {
  AppValidators get validators => AppValidators(s.common);
}

/// Legacy English-only API kept so old screens compile; new code uses `context.validators`.
class Validators {
  Validators._();
  static final AppValidators _v = AppValidators(S.en.common);

  static String? required(String? value, {String field = 'This field'}) =>
      _v.required(value, field);
  static String? email(String? value) => _v.email(value);
  static String? password(String? value) => _v.password(value);
  static String? confirmPassword(String? value, String original) =>
      _v.confirmPassword(() => original)(value);
  static String? phone(String? value, {bool optional = false}) =>
      optional ? _v.optionalPhone(value) : _v.phone(value);
  static String? address(String? value) => _v.address(value);
  static String? name(String? value, {String field = 'Name'}) =>
      _v.name(field)(value);
  static String? price(String? value, {String field = 'Price'}) =>
      _v.price(value);
  static String? nonNegativeNumber(String? value, {String field = 'Value'}) =>
      _v.nonNegative(field)(value);
  static String? restaurantName(String? value) =>
      _v.name('Restaurant name')(value);
  static String? cuisineType(String? value) =>
      _v.required(value, 'Cuisine type');
  static FieldValidator combine(List<FieldValidator> validators) =>
      AppValidators.combine(validators);
}
