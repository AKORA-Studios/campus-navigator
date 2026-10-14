import 'package:flutter/widgets.dart';

import 'app_settings_controller.dart';

/// Inherited access point shared by the root app and settings page.
class AppSettingsScope extends InheritedNotifier<AppSettingsController> {
  const AppSettingsScope({
    super.key,
    required AppSettingsController controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  static AppSettingsController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppSettingsScope>()?.notifier;

  static AppSettingsController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    assert(scope != null, 'AppSettingsScope is missing above this context.');
    return scope!.notifier!;
  }
}
