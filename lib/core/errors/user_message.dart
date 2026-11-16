import 'dart:async';
import 'package:flutter/widgets.dart';
import '../backend/supabase/supabase_error_mapper.dart';
import '../l10n/s.dart';
import '../l10n/strings/common_strings.dart';

/// An error whose message is already safe and friendly to show as-is.
class UserFacingException implements Exception {
  const UserFacingException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The one way to turn any error into text for the user.
String userMessage(BuildContext context, Object? error) =>
    userMessageFor(context.s.common, error);

String userMessageFor(CommonStrings c, Object? error) {
  if (error == null) return c.errGeneric;
  if (error is String) return error.isEmpty ? c.errGeneric : error;
  if (error is UserFacingException) return error.message;
  final backend = mapSupabaseError(error, c);
  if (backend != null) return backend;
  if (error is TimeoutException) return c.errTimeout;

  final text = error.toString().toLowerCase();
  if (text.contains('socketexception') ||
      text.contains('failed host lookup') ||
      text.contains('clientexception') ||
      text.contains('network is unreachable') ||
      text.contains('xmlhttprequest error') ||
      text.contains('connection refused')) {
    return c.errNoInternet;
  }

  // Plain `Exception('…')` thrown by our own code carries a readable message.
  final raw = error.toString();
  if (raw.startsWith('Exception: ')) {
    final msg = raw.substring('Exception: '.length);
    if (msg.length <= 160 && !msg.contains('{') && !msg.contains('Error')) {
      return msg;
    }
  }
  return c.errGeneric;
}
