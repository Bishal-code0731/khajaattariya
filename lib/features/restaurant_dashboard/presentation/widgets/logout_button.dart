import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/s.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../../shared/widgets/app_dialog.dart';

/// Asks before logging out, then signs out (the router takes the owner back to the login screen).
Future<void> confirmAndLogout(BuildContext context, WidgetRef ref) async {
  final s = context.s;
  final ok = await AppDialog.confirm(
    context,
    title: s.restaurant.logoutConfirmTitle,
    message: s.restaurant.logoutConfirmMessage,
    confirmLabel: s.common.logout,
    icon: Icons.logout_rounded,
  );
  if (ok) await ref.read(authNotifierProvider.notifier).signOut();
}

/// Top-bar log-out icon.
class LogoutButton extends ConsumerWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: context.s.common.logout,
      icon: const Icon(Icons.logout_rounded),
      onPressed: () => confirmAndLogout(context, ref),
    );
  }
}
