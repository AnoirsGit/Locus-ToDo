import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ToastKind { info, error }

class ToastMessage {
  final String text;
  final ToastKind kind;
  const ToastMessage(this.text, {this.kind = ToastKind.error});
}

class AppToastNotifier extends StateNotifier<ToastMessage?> {
  AppToastNotifier() : super(null);

  void show(String text, {ToastKind kind = ToastKind.error}) =>
      state = ToastMessage(text, kind: kind);

  void clear() => state = null;
}

final appToastProvider =
    StateNotifierProvider<AppToastNotifier, ToastMessage?>(
  (_) => AppToastNotifier(),
);
