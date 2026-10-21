import 'package:supabase_flutter/supabase_flutter.dart';
import '../../l10n/strings/common_strings.dart';

/// Turns Supabase errors into friendly, translated messages.
String? mapSupabaseError(Object error, CommonStrings c) {
  if (error is AuthException) return _auth(error, c);
  if (error is PostgrestException) return _postgrest(error, c);
  if (error is StorageException) return _storage(error, c);
  if (error is FunctionException) return c.errGeneric;
  return null;
}

String _auth(AuthException e, CommonStrings c) {
  final m = e.message.toLowerCase();
  final code = (e.code ?? '').toLowerCase();
  bool any(List<String> codes, List<String> phrases) =>
      codes.contains(code) || phrases.any(m.contains);

  if (any(
      ['otp_expired', 'otp_disabled'], ['token has expired', 'invalid otp'])) {
    return c.errOtpInvalid;
  }
  if (any(['invalid_credentials'], ['invalid login credentials'])) {
    return c.errInvalidLogin;
  }
  if (any(['email_not_confirmed'], ['email not confirmed'])) {
    return c.errEmailNotConfirmed;
  }
  if (any(['user_already_exists', 'email_exists'],
      ['already registered', 'already been registered'])) {
    return c.errEmailTaken;
  }
  if (any(['weak_password'], ['password should'])) return c.errWeakPassword;
  if (code.contains('rate_limit') ||
      m.contains('rate limit') ||
      m.contains('too many')) {
    return c.errTooManyAttempts;
  }
  if (code == 'user_banned') return c.errAccountDisabled;
  if (any(['session_not_found'], ['jwt', 'refresh token'])) {
    return c.errSessionExpired;
  }
  return c.errGeneric;
}

String _postgrest(PostgrestException e, CommonStrings c) {
  final code = e.code ?? '';
  final msg = e.message;
  // Our own database functions raise short, user-ready sentences.
  if ((code == 'P0001' || code == '42501') && _isFriendly(msg)) return msg;
  if (code == '42501' || msg.contains('row-level security')) {
    return c.errPermission;
  }
  if (code == '23505') return c.errDuplicate;
  if (code == 'PGRST116') return c.errNotFound;
  if (code == 'PGRST301' || msg.toLowerCase().contains('jwt')) {
    return c.errSessionExpired;
  }
  return c.errGeneric;
}

String _storage(StorageException e, CommonStrings c) {
  final m = e.message.toLowerCase();
  if (m.contains('size') || m.contains('too large') || e.statusCode == '413') {
    return c.errUploadTooLarge;
  }
  if (e.statusCode == '403' || m.contains('policy')) return c.errPermission;
  return c.errGeneric;
}

bool _isFriendly(String message) =>
    message.isNotEmpty &&
    message.length <= 160 &&
    !message.contains('violates') &&
    !message.contains('relation ') &&
    !message.contains('function ') &&
    !message.contains('column ');
