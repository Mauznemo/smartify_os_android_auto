import 'package:smartify_os_android_auto/src/i18n/strings.g.dart';
import 'package:smartify_os_android_auto/src/services/android_auto/models/android_auto_state.dart';

/// Internal: what Android Auto is doing, in the words the notification and
/// Settings both use, so the two never disagree.
String androidAutoStatusText(AndroidAutoState state) => switch (state.phase) {
  AndroidAutoPhase.stopped => t.android_auto.status_stopped,
  AndroidAutoPhase.waitingForPhone => t.android_auto.status_waiting,
  AndroidAutoPhase.startingHotspot => t.android_auto.status_starting_hotspot,
  AndroidAutoPhase.connecting => t.android_auto.status_connecting,
  AndroidAutoPhase.connected => switch (state.connection) {
    AndroidAutoConnection.wireless => t.android_auto.status_connected_wireless,
    _ => t.android_auto.status_connected_cable,
  },
};
