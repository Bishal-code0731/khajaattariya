import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/errors/user_message.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/widgets/app_snackbar.dart';

Future<void> openAddressInMaps(BuildContext context, String address) async {
  final query = address.toLowerCase().contains('attariya')
      ? address
      : '$address, Attariya, Kailali';
  final uri = Uri.https(
      'www.google.com', '/maps/search/', {'api': '1', 'query': query});
  final failMessage = context.s.rider.couldNotOpenMaps;
  var ok = false;
  try {
    ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!ok && context.mounted) {
    AppSnackbar.error(context, UserFacingException(failMessage));
  }
}

/// Starts a phone call to [phone].
Future<void> callPhone(BuildContext context, String phone) async {
  final uri = Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^\d+]'), ''));
  final failMessage = context.s.rider.couldNotCall;
  var ok = false;
  try {
    ok = await launchUrl(uri);
  } catch (_) {
    ok = false;
  }
  if (!ok && context.mounted) {
    AppSnackbar.error(context, UserFacingException(failMessage));
  }
}

/// Calls the support line when one is configured, otherwise opens the in-app help screen.
Future<void> contactSupport(BuildContext context, String? supportPhone) async {
  if (supportPhone != null) {
    await callPhone(context, supportPhone);
  } else {
    await context.push(RouteNames.support);
  }
}
