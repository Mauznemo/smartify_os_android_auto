import 'package:android_auto/android_auto.dart';
import 'package:flutter/widgets.dart';
import 'package:smartify_os_android_auto/src/services/android_auto/android_auto_service.dart';
import 'package:smartify_os_android_auto/src/services/android_auto/models/android_auto_state.dart';
import 'package:smartify_os_core/media.dart';

/// Android Auto, from anywhere in your app.
///
/// Everything a driver can do with it already has a place on screen (the app
/// list, the notification, Settings), so you only need this to drive it from
/// somewhere else, a steering wheel button, say:
///
/// ```dart
/// if (SmartifyOsAndroidAuto.state.isRunning) {
///   SmartifyOsAndroidAuto.stopSession();
/// } else {
///   SmartifyOsAndroidAuto.startSession();
/// }
/// ```
///
/// Watch `androidAutoStateProvider` to follow it on screen. None of these
/// throw, and on a machine where Android Auto cannot run (Android, for now)
/// they do nothing: check [isSupported] before offering them.
class SmartifyOsAndroidAuto {
  SmartifyOsAndroidAuto._();

  static AndroidAutoService get _service => AndroidAutoService.instance;

  /// Whether Android Auto can run on this machine at all.
  static bool get isSupported => _service.isSupported;

  /// Everything about Android Auto worth showing right now.
  static AndroidAutoState get state => _service.state;

  /// Emits every time [state] changes, starting with what it is now.
  static Stream<AndroidAutoState> get stateChanges => _service.changes;

  /// The head unit itself, or `null` where there is none.
  ///
  /// This is where to build your own screens on top of Android Auto: the
  /// turn by turn guidance (`navigation`), what is playing
  /// (`mediaPlayback`), calls (`phoneStatus`), the steering wheel keys
  /// (`pressKey`) and what the car tells the phone (`setNightMode`,
  /// `setSpeed` and the rest). See the android_auto package for all of it.
  static AndroidAutoController? get controller => _service.controller;

  /// What the connected phone is playing, the way the home screen's player
  /// card shows it, or `null`. Watch `androidAutoNowPlayingProvider` to
  /// follow it.
  static MediaPlayerInfo? get nowPlaying => _service.nowPlaying;

  /// The guidance in progress, or `null` while no connected phone is guiding.
  /// Watch `androidAutoNavigationProvider` to follow it.
  static AndroidAutoNavigation? get navigation => _service.navigation;

  /// Starts Android Auto: a phone on the cable projects straight away, and
  /// one connected over Bluetooth is offered it without a cable. Does
  /// nothing if it is already running.
  static Future<void> startSession() => _service.startSession();

  /// Stops Android Auto, the same as the Stop button on its notification.
  static Future<void> stopSession() => _service.stopSession();

  /// Opens the Android Auto window, which starts Android Auto if it is not
  /// running yet.
  static void openWindow(BuildContext context) => _service.openWindow(context);

  /// Whether Android Auto starts by itself when a phone is plugged in, or a
  /// phone that has used it without a cable here connects over Bluetooth.
  /// Remembered between drives.
  static Future<void> setAutostart(bool on) => _service.setAutostart(on);

  /// Whether Android Auto may connect without a cable. Remembered between
  /// drives.
  static Future<void> setWireless(bool on) => _service.setWireless(on);

  /// Whether what the phone is playing gets a card on the home screen.
  /// Remembered between drives.
  static Future<void> setShowPlayer(bool on) => _service.setShowPlayer(on);

  /// Whether the phone's directions get a card on the home screen.
  /// Remembered between drives.
  static Future<void> setShowNavigation(bool on) =>
      _service.setShowNavigation(on);

  /// Forgets every phone that starts Android Auto over Bluetooth. They are
  /// learned again the next time they connect without a cable.
  static Future<void> forgetWirelessPhones() => _service.forgetWirelessPhones();
}
