import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';

import '../core/constants/app_constants.dart';
import '../core/widgets/app_toast.dart';
import 'router/app_router.dart';
import 'theme/theme.dart';

/// The root widget: theme, router, and nothing else.
///
/// Bootstrap work lives in `main.dart`; feature logic lives in `features/`.
/// Keeping this widget thin means a change to either does not touch it.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Lets `AppToast` show messages without a BuildContext, above every route.
    return ToastificationWrapper(
      config: AppToast.config,
      child: MaterialApp.router(
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        routerConfig: ref.watch(appRouterProvider),
      ),
    );
  }
}
