import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../../app/theme/theme.dart';

/// Short-lived message shown at the top center of the screen.
///
/// Needs a [ToastificationWrapper] above the app, configured with [config].
/// The toast lives in that wrapper's overlay rather than a page's, so it stays
/// up while the page that raised it pops or the router redirects away.
abstract final class AppToast {
  static const _visibleFor = Duration(seconds: 3);

  /// Placement shared by every toast. One at a time: a new message replaces
  /// the old one instead of stacking under it.
  static const config = ToastificationConfig(
    alignment: Alignment.topCenter,
    maxToastLimit: 1,
    maxTitleLines: 3,
  );

  static void success(String message) => _show(
        message,
        type: ToastificationType.success,
        color: AppColors.primary,
        icon: Icons.check_circle_rounded,
      );

  static void error(String message) => _show(
        message,
        type: ToastificationType.error,
        color: AppColors.error,
        icon: Icons.error_outline_rounded,
      );

  static void _show(
    String message, {
    required ToastificationType type,
    required Color color,
    required IconData icon,
  }) {
    toastification.show(
      type: type,
      style: ToastificationStyle.flatColored,
      title: Text(message),
      icon: Icon(icon),
      primaryColor: color,
      autoCloseDuration: _visibleFor,
      showProgressBar: false,
      closeButton: const ToastCloseButton(showType: CloseButtonShowType.none),
      closeOnClick: true,
      dragToClose: true,
    );
  }
}
