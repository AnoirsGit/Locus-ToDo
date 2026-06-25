import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// App-wide SnackBar toasts, callable without a [BuildContext] (e.g. from
/// notifiers/sync workers). Mirrors the web `toastStore` error/success/info
/// semantics. Wire [appMessengerKey] into `MaterialApp.scaffoldMessengerKey`.
final appMessengerKey = GlobalKey<ScaffoldMessengerState>();

enum _ToastKind { error, success, info }

class AppToast {
  static void error(String message) => _show(message, _ToastKind.error);
  static void success(String message) => _show(message, _ToastKind.success);
  static void info(String message) => _show(message, _ToastKind.info);

  static void _show(String message, _ToastKind kind) {
    final messenger = appMessengerKey.currentState;
    final context = appMessengerKey.currentContext;
    if (messenger == null || context == null) return;

    final accent = switch (kind) {
      _ToastKind.error => context.colorDanger,
      _ToastKind.success => context.colorSuccess,
      _ToastKind.info => context.colorBrand,
    };
    final icon = switch (kind) {
      _ToastKind.error => Icons.error_outline,
      _ToastKind.success => Icons.check_circle_outline,
      _ToastKind.info => Icons.info_outline,
    };

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.colorSurface2,
          duration: Duration(seconds: kind == _ToastKind.error ? 5 : 3),
          content: Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: context.colorTextStrong, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
