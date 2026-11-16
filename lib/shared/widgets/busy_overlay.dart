import 'package:flutter/material.dart';

class BusyOverlay extends StatelessWidget {
  const BusyOverlay({super.key, required this.busy, required this.child});

  final bool busy;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !busy,
      child: Semantics(
        // Tell screen readers the screen is working.
        liveRegion: busy,
        child: ExcludeFocus(
          excluding: busy,
          child: AbsorbPointer(absorbing: busy, child: child),
        ),
      ),
    );
  }
}
