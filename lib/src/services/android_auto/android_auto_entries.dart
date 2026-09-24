import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smartify_os_android_auto/src/i18n/strings.g.dart';
import 'package:smartify_os_android_auto/src/providers/android_auto_provider.dart';
import 'package:smartify_os_android_auto/src/services/android_auto/android_auto_service.dart';
import 'package:smartify_os_android_auto/src/utils/android_auto_status_text.dart';
import 'package:smartify_os_android_auto/src/widgets/android_auto_icon.dart';
import 'package:smartify_os_core/app_list.dart';
import 'package:smartify_os_core/bluetooth.dart';
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
}

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
