import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'error_state_view.dart';
import 'loading_indicator.dart';

/// Thin wrapper around `AsyncValue.when` so every screen gets the
/// same loading/error treatment by default instead of hand-rolling
/// (or silently swallowing) its own. Pass [onRetry] to show a retry
/// button on error, or override [error]/[loading] for a bespoke look.
class AsyncValueView<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget Function(Object error, StackTrace stackTrace)? error;
  final Widget Function()? loading;
  final VoidCallback? onRetry;
  final String? errorMessage;

  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.error,
    this.loading,
    this.onRetry,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    // A `ref.invalidate()`-triggered refresh puts the provider back into
    // AsyncLoading, but Riverpod keeps the previous value attached to it
    // — so a "loading" state with data already in hand means "refreshing
    // in the background", not "nothing to show yet". Keep rendering the
    // existing content in that case instead of wiping it with a spinner;
    // only fall back to the loading widget when there's truly nothing.
    if (value.hasValue) {
      return data(value.value as T);
    }

    return value.when(
      data: data,
      loading: loading ?? () => const AppLoader.fullscreen(),
      error: error ??
          (err, _) => AppErrorState(
                message: errorMessage ?? 'Something went wrong. Please try again.',
                onRetry: onRetry,
              ),
    );
  }
}
