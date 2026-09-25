import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smartify_os_android_auto/src/i18n/strings.g.dart';
import 'package:smartify_os_android_auto/src/providers/android_auto_provider.dart';
import 'package:smartify_os_android_auto/src/services/android_auto/android_auto_service.dart';
import 'package:smartify_os_android_auto/src/utils/android_auto_status_text.dart';
import 'package:smartify_os_android_auto/src/widgets/android_auto_icon.dart';
import 'package:smartify_os_android_auto/src/widgets/home_widgets/android_auto_navigation_home_widget.dart';
import 'package:smartify_os_android_auto/src/widgets/home_widgets/android_auto_player_home_widget.dart';
import 'package:smartify_os_core/app_list.dart';
import 'package:smartify_os_core/bluetooth.dart';
import 'package:smartify_os_core/gps.dart';
import 'package:smartify_os_core/home_widgets.dart';
import 'package:smartify_os_core/settings.dart';

/// The names of what the Android Auto extension adds, to hide or find any of
/// it:
///
/// ```dart
/// await SmartifyOs().init(
///   // Android Auto only ever starts on its own or from a button of yours.
///   appList: const AppListConfig(
///     hiddenEntries: [AndroidAutoIds.appListEntry],
///   ),
///   extensions: [const AndroidAutoExtension()],
/// );
/// ```
class AndroidAutoIds {
  AndroidAutoIds._();

  /// The entry in the app list.
  static const String appListEntry = 'android_auto';

  /// The page in Settings, under Connectivity.
  static const String settingsPage = 'android_auto';

  /// The ongoing notification shown while Android Auto runs, which also puts
  /// its icon in the status bar.
  static const String notification = AndroidAutoService.notificationId;

  /// The home screen card with what the phone is playing. It stands in for
  /// `HomeWidgets.bluetoothPlayer` while it is there.
  static const String playerWidget = 'android_auto.player';

  /// The home screen card with the next turn, while the phone is guiding.
  static const String navigationWidget = 'android_auto.navigation';
}

/// Internal: the two cards on the home screen. Each checks the driver's own
/// switch for it in Settings, so hiding one there never touches what the app
/// or the driver chose about the card itself.
List<HomeWidget> androidAutoHomeWidgets() => [
  HomeWidget(
    id: AndroidAutoIds.navigationWidget,
    // Before the music: the next turn is the more urgent of the two.
    order: 10,
    visible: (home) {
      final service = AndroidAutoService.instance;
      final state =
          home.ref.watch(androidAutoStateProvider).value ?? service.state;
      final navigation =
          home.ref.watch(androidAutoNavigationProvider).value ??
          service.navigation;
      return state.showNavigation && navigation != null;
    },
    onTap: AndroidAutoService.instance.openWindow,
    builder: (home) => const AndroidAutoNavigationHomeWidget(),
  ),
  HomeWidget(
    id: AndroidAutoIds.playerWidget,
    // Where the Bluetooth player sits, since this takes its place.
    order: 20,
    // The phone reports the same song over Bluetooth too, and one card per
    // song is enough.
    replaces: const {HomeWidgets.bluetoothPlayer},
    visible: (home) {
      final service = AndroidAutoService.instance;
      final state =
          home.ref.watch(androidAutoStateProvider).value ?? service.state;
      final playing =
          home.ref.watch(androidAutoNowPlayingProvider).value ??
          service.nowPlaying;
      return state.showPlayer && playing != null;
    },
    onTap: AndroidAutoService.instance.openWindow,
    builder: (home) => const AndroidAutoPlayerHomeWidget(),
  ),
];

/// Internal: the entry in the app list that opens the Android Auto window.
AppListEntry androidAutoAppListEntry() => AppListEntry(
  id: AndroidAutoIds.appListEntry,
  title: t.android_auto.title,
  icon: const AndroidAutoIcon(),
  // Before Settings, which SmartifyOS keeps last at 900.
  order: 100,
  onOpen: AndroidAutoService.instance.openWindow,
);

/// Internal: the Android Auto page in Settings.
SettingsPage androidAutoSettingsPage() => SettingsPage.builder(
  id: AndroidAutoIds.settingsPage,
  parent: SettingsPages.connectivity,
  title: t.android_auto.title,
  icon: const AndroidAutoIcon(),
  // Right after Bluetooth, which it builds on.
  order: 15,
  entries: (settings) {
    final service = AndroidAutoService.instance;
    final state =
        settings.ref.watch(androidAutoStateProvider).value ?? service.state;
    // Watched so the phones' names below follow Bluetooth.
    final devices =
        settings.ref.watch(bluetoothDevicesProvider).value ?? Bluetooth.devices;
    final phoneNames = [
      for (final address in state.wirelessPhones)
        devices
                .where((device) => device.address == address)
                .firstOrNull
                ?.name ??
            address,
    ];
    final phones = t.settings.phones;
    final capabilities =
        settings.ref.watch(gpsCapabilitiesProvider).value ??
        SmartifyOsGps.capabilities;
    final carKnowsPosition = capabilities.has(GpsCapability.position);

    return [
      SettingsEntry.info(
        title: t.settings.status,
        value: androidAutoStatusText(state),
        subtitle: state.problem,
      ),
      if (state.isRunning)
        SettingsEntry.action(
          title: t.settings.stop,
          icon: const Icon(Icons.stop),
          onTap: () => unawaited(service.stopSession()),
        )
      else
        SettingsEntry.action(
          title: t.settings.start,
          icon: const Icon(Icons.play_arrow),
          onTap: () => service.openWindow(settings.context),
        ),
      SettingsEntry.toggle(
        title: t.settings.autostart,
        subtitle: t.settings.autostart_hint,
        initialValue: state.autostart,
        onChanged: (on) => unawaited(service.setAutostart(on)),
      ),
      if (state.wirelessAvailable)
        SettingsEntry.toggle(
          title: t.settings.wireless,
          subtitle: state.hotspotName == null
              ? t.settings.wireless_hint_existing
              : t.settings.wireless_hint_hotspot,
          initialValue: state.wireless,
          onChanged: (on) => unawaited(service.setWireless(on)),
        ),
      if (state.usesWireless && state.hotspotName != null)
        SettingsEntry.info(
          title: t.settings.hotspot_name,
          value: state.hotspotName!,
        ),
      SettingsEntry.toggle(
        title: t.settings.use_car_gps,
        subtitle: state.useCarGps != service.offersCarGps
            ? t.settings.use_car_gps_restart
            : carKnowsPosition
            ? t.settings.use_car_gps_hint
            : t.settings.use_car_gps_unavailable,
        initialValue: state.useCarGps,
        // Still switchable off when the car has lost its position since.
        enabled: carKnowsPosition || state.useCarGps,
        onChanged: (on) => unawaited(service.setUseCarGps(on)),
      ),
      SettingsEntry.toggle(
        title: t.settings.show_navigation,
        subtitle: t.settings.show_navigation_hint,
        initialValue: state.showNavigation,
        section: t.settings.home_screen,
        onChanged: (on) => unawaited(service.setShowNavigation(on)),
      ),
      SettingsEntry.toggle(
        title: t.settings.show_player,
        subtitle: t.settings.show_player_hint,
        initialValue: state.showPlayer,
        section: t.settings.home_screen,
        onChanged: (on) => unawaited(service.setShowPlayer(on)),
      ),
      if (state.wirelessAvailable) ...[
        SettingsEntry.info(
          title: t.settings.wireless_phones,
          value: phoneNames.isEmpty
              ? t.settings.wireless_phones_none
              : phoneNames.join(', '),
          section: phones,
        ),
        if (phoneNames.isNotEmpty)
          SettingsEntry.action(
            title: t.settings.forget_phones,
            subtitle: t.settings.forget_phones_hint,
            destructive: true,
            section: phones,
            onTap: () => unawaited(service.forgetWirelessPhones()),
          ),
        SettingsEntry.info(
          title: t.settings.pair_again_title,
          subtitle: t.settings.pair_again_hint,
          value: '',
          section: phones,
        ),
      ],
    ];
  },
);
