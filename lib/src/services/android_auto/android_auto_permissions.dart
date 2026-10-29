import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:smartify_os_core/utils.dart';

/// Internal: asks the driver for what Android Auto needs on Android, the
/// first time a session starts there.
///
/// Every one of them makes less work rather than nothing at all when it is
/// refused: without the microphone the phone's assistant hears silence,
/// without Bluetooth no phone can connect without a cable, and without the
/// other two Android will not bring up the hotspot a phone joins for that.
///
/// The car's app has to list `ACCESS_FINE_LOCATION` in its
/// `AndroidManifest.xml`, or Android refuses it without asking. The rest the
/// android_auto plugin lists itself.
class AndroidAutoPermissions {
  static const _tag = 'AndroidAuto';

  static const _wanted = [
    Permission.microphone,
    Permission.bluetoothConnect,
    Permission.nearbyWifiDevices,
    Permission.locationWhenInUse,
  ];

  /// Asks for whichever of them is not allowed yet. Does nothing off Android,
  /// and never throws.
  static Future<void> request() async {
    if (!Platform.isAndroid) return;
    try {
      final missing = [
        for (final permission in _wanted)
          if (!await permission.isGranted) permission,
      ];
      if (missing.isEmpty) return;
      final answers = await missing.request();
      final refused = [
        for (final entry in answers.entries)
          if (!entry.value.isGranted) entry.key,
      ];
      if (refused.isNotEmpty) {
        SmartifyOsLog.warning(_tag, 'Not allowed: ${refused.join(', ')}');
      }
    } on Object catch (error) {
      SmartifyOsLog.warning(_tag, 'Could not ask for permissions', error);
    }
  }
}
