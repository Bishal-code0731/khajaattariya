import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/app_snackbar.dart';

mixin AdminBusy<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  String? busy;

  bool get isBusy => busy != null;

  Future<bool> runAction(String key, Future<void> Function() action,
      {String? success}) async {
    if (busy != null) return false;
    setState(() => busy = key);
    try {
      await action();
      if (mounted && success != null) AppSnackbar.success(context, success);
      return true;
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e);
      return false;
    } finally {
      if (mounted) setState(() => busy = null);
    }
  }
}
