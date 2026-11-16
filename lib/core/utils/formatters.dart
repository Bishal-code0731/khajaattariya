import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import '../l10n/s.dart';

class AppFormat {
  AppFormat._();

  static final NumberFormat _grouped = NumberFormat('#,##,##0', 'en_IN');
  static final NumberFormat _groupedDecimals =
      NumberFormat('#,##,##0.00', 'en_IN');

  /// `Rs 1,250` / `रु 1,250`; decimals only when not a whole number.
  static String money(BuildContext context, num amount) =>
      moneyWith(context.s, amount);

  static String moneyWith(S s, num amount) {
    final isWhole = amount == amount.roundToDouble();
    final number =
        isWhole ? _grouped.format(amount) : _groupedDecimals.format(amount);
    return '${s.common.currency} $number';
  }

  static String _locale(BuildContext context) => context.s.isNe ? 'ne' : 'en';

  /// 14 Nov 2026
  static String date(BuildContext context, DateTime d) =>
      DateFormat.yMMMd(_locale(context)).format(d.toLocal());

  /// 7:30 PM
  static String time(BuildContext context, DateTime d) =>
      DateFormat.jm(_locale(context)).format(d.toLocal());

  /// 14 Nov, 7:30 PM
  static String dateTime(BuildContext context, DateTime d) =>
      DateFormat('d MMM, h:mm a', _locale(context)).format(d.toLocal());

  /// Just now / 5m ago / 3h ago / Yesterday / 4d ago / 14 Nov 2026
  static String timeAgo(BuildContext context, DateTime d) {
    final c = context.s.common;
    final diff = DateTime.now().difference(d.toLocal());
    if (diff.inMinutes < 1) return c.justNow;
    if (diff.inMinutes < 60) return c.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return c.hoursAgo(diff.inHours);
    if (diff.inDays == 1) return c.yesterday;
    if (diff.inDays < 7) return c.daysAgo(diff.inDays);
    return date(context, d);
  }

  /// Short order code shown to people: #A1B2C3D4
  static String orderCode(String orderId) =>
      '#${orderId.replaceAll('-', '').substring(0, 8).toUpperCase()}';

  /// "98XXXXXXXX" → "98X-XXX-XXXX"
  static String phone(String raw) {
    final d = raw.replaceAll(RegExp(r'\D'), '');
    final local = d.length > 10 ? d.substring(d.length - 10) : d;
    if (local.length != 10) return raw;
    return '${local.substring(0, 3)}-${local.substring(3, 6)}-${local.substring(6)}';
  }
}
