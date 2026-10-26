import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'error_state_view.dart';
import 'loading_indicator.dart';

class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.error,
    this.loading,
    this.onRetry,
    this.errorMessage,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget Function(Object error, StackTrace stackTrace)? error;
  final Widget Function()? loading;
  final VoidCallback? onRetry;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (value.hasValue) return data(value.value as T);
    return value.when(
      data: data,
      loading: loading ?? () => const AppLoader.fullscreen(),
      error: error ??
          (err, _) => AppErrorState(
              message: errorMessage, error: err, onRetry: onRetry),
    );
  }
}
