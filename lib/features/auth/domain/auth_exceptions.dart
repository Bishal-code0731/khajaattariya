/// Sign-up worked, but the backend wants the email confirmed before the first login.
class EmailConfirmationRequiredException implements Exception {
  const EmailConfirmationRequiredException(this.email);
  final String email;

  @override
  String toString() => 'EmailConfirmationRequiredException';
}

/// The profile exists but an admin has disabled it (`is_active = false`).
class AccountDisabledException implements Exception {
  const AccountDisabledException();

  @override
  String toString() => 'AccountDisabledException';
}

/// Login with an email that was never verified.
class EmailNotVerifiedException implements Exception {
  const EmailNotVerifiedException(this.email);
  final String email;

  @override
  String toString() => 'EmailNotVerifiedException';
}
