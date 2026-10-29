import 'package:smartify_os_android_auto/src/services/android_auto/wifi_hotspot.dart';

/// A car without Wi-Fi, without running `nmcli` on this computer.
class NoHotspot extends WifiHotspot {
  @override
  Future<HotspotResult> bringUp({
    required String name,
    required String passphrase,
  }) async => const HotspotResult.failed('No Wi-Fi in a test');

  @override
  Future<void> removeLeftover() async {}
}
