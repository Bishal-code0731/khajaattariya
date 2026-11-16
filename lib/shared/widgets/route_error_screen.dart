import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/s.dart';
import '../../core/router/route_names.dart';
import 'app_button.dart';
import 'app_top_bar.dart';
import 'empty_state_view.dart';

class RouteErrorScreen extends StatelessWidget {
  const RouteErrorScreen({super.key, this.details});

  final String? details;

  @override
  Widget build(BuildContext context) {
    final c = context.s.common;
    return Scaffold(
      appBar: const AppTopBar(title: ''),
      body: AppEmptyState(
        icon: Icons.wrong_location_rounded,
        title: c.notFoundTitle,
        subtitle: c.notFoundBody,
        action: AppButton(
          label: c.goHome,
          leadingIcon: Icons.home_rounded,
          expand: false,
          onPressed: () => context.go(RouteNames.home),
        ),
      ),
    );
  }
}
