import 'dart:io';

import 'package:smartify_os_core/shell.dart';
import 'package:smartify_os_core/utils.dart';

/// Internal: brings up the Wi-Fi hotspot a phone joins to use Android Auto
/// without a cable, and takes it down again.
///
/// Drives NetworkManager through `nmcli`, as root. The profile is built by
/// hand rather than with `nmcli device wifi hotspot`, because the phone is
/// told the network is WPA2 personal and has to find exactly that: RSN, CCMP,
/// plain PSK, management frame protection off. The convenience command picks
/// its own mode, and on NetworkManager 1.54 picks one a phone cannot join,
/// which the phone then reports as a wrong password. The android_auto
/// repository's `tools/wireless-ap.sh` is where all of this was worked out.
///
/// Linux only. It never throws: whatever goes wrong comes back in
/// [HotspotResult.error].
class WifiHotspot {
  static const _tag = 'AndroidAuto';

  /// The NetworkManager profile this owns. Deleted and made again every time,
  /// so a profile left behind by a crash never gets in the way.
  static const connectionName = 'smartify-os-android-auto';

  /// How long NetworkManager is given to bring the access point up. It waits
  /// ninety seconds in silence on a channel the driver will not beacon on, so
  /// this is kept short and the next band is tried instead.
  static const _upTimeout = Duration(seconds: 25);

  bool _up = false;

  /// Whether this brought the hotspot up and has not taken it down yet.
  bool get isUp => _up;

  /// Brings the hotspot up, on 5 GHz where the machine may beacon there and
  /// on 2.4 GHz otherwise.
  Future<HotspotResult> bringUp({
    required String name,
    required String passphrase,
  }) async {
    if (!Platform.isLinux) {
      return const HotspotResult.failed('Only possible on Linux');
    }
    if (!await SmartifyOsShell.has('nmcli')) {
      return const HotspotResult.failed('NetworkManager (nmcli) is missing');
    }

    final device = await _wifiDevice();
    if (device == null) {
      return const HotspotResult.failed('This machine has no Wi-Fi');
    }

    final channel = await _usable5GhzChannel(device);
    SmartifyOsLog.info(
      _tag,
      'Bringing up the hotspot "$name" on $device, '
      '${channel == null ? '2.4 GHz channel 6' : '5 GHz channel $channel'}',
    );

    // A profile left over from last time, or from a crash, would otherwise
    // make the add below fail. Not being there is fine.
    await _nmcli(['connection', 'delete', connectionName]);
    final added = await _nmcli([
      'connection', 'add', 'type', 'wifi', //
      'ifname', device,
      'con-name', connectionName,
      'autoconnect', 'no',
      'ssid', name,
      '802-11-wireless.mode', 'ap',
      '802-11-wireless.band', channel == null ? 'bg' : 'a',
      '802-11-wireless.channel', '${channel ?? 6}',
      '802-11-wireless-security.key-mgmt', 'wpa-psk',
      '802-11-wireless-security.proto', 'rsn',
      '802-11-wireless-security.pairwise', 'ccmp',
      '802-11-wireless-security.group', 'ccmp',
      // 1 is "disable". A phone told WPA2 personal will not join a network
      // that requires protected management frames.
      '802-11-wireless-security.pmf', '1',
      '802-11-wireless-security.psk', passphrase,
      'wifi.cloned-mac-address', 'permanent',
      'ipv4.method', 'shared',
      'ipv6.method', 'ignore',
    ]);
    if (!added.ok) return HotspotResult.failed(added.error);

    var up = await _activate();
    if (!up.ok && channel != null) {
      SmartifyOsLog.warning(
        _tag,
        'The hotspot would not start on 5 GHz, trying 2.4 GHz',
        up.error,
      );
      await _nmcli([
        'connection', 'modify', connectionName, //
        '802-11-wireless.band', 'bg',
        '802-11-wireless.channel', '6',
      ]);
      up = await _activate();
    }
    if (!up.ok) {
      await _nmcli(['connection', 'delete', connectionName]);
      return HotspotResult.failed(up.error);
    }

    _up = true;
    SmartifyOsLog.info(_tag, 'Hotspot is up on $device');
    return HotspotResult.up(device);
  }

  /// Takes the hotspot down and deletes its profile, which gives the Wi-Fi
  /// back to whatever network the car is normally on.
  Future<void> takeDown() async {
    if (!_up) return;
    _up = false;
    await _nmcli(['connection', 'down', connectionName]);
    await _nmcli(['connection', 'delete', connectionName]);
    SmartifyOsLog.info(_tag, 'Hotspot is down');
  }

  /// Deletes the profile if it is still there from a run that never got to
  /// take it down, which takes the hotspot down with it.
  Future<void> removeLeftover() async {
    if (!Platform.isLinux || !await SmartifyOsShell.has('nmcli')) return;
    final result = await _nmcli(['connection', 'delete', connectionName]);
    if (result.ok) {
      SmartifyOsLog.info(_tag, 'Took down a hotspot left over from before');
    }
  }

  Future<ShellResult> _activate() => _nmcli([
    '--wait',
    '${_upTimeout.inSeconds}',
    'connection',
    'up',
    connectionName,
  ], timeout: _upTimeout + const Duration(seconds: 5));

  Future<ShellResult> _nmcli(
    List<String> arguments, {
    Duration timeout = SmartifyOsShell.defaultTimeout,
  }) => SmartifyOsShell.run(
    'nmcli',
    arguments: arguments,
    elevated: true,
    timeout: timeout,
  );

  /// The first Wi-Fi interface NetworkManager knows, `wlan0` and the like.
  Future<String?> _wifiDevice() async {
    final result = await SmartifyOsShell.run(
      'nmcli',
      arguments: ['-t', '-f', 'DEVICE,TYPE', 'device'],
    );
    if (!result.ok) return null;
    for (final line in result.output.split('\n')) {
      final fields = line.split(':');
      if (fields.length >= 2 && fields[1] == 'wifi') return fields[0];
    }
    return null;
  }

  /// The lowest 5 GHz channel the kernel lets this machine beacon on, or
  /// `null` when there is none.
  ///
  /// Hardcoding one does not work: on many cards every channel below 149 is
  /// marked "no IR" (may not initiate radiation, so no access point), and
  /// which ones are depends on the regulatory domain. `(disabled)` channels
  /// do not say "no IR" and are not usable either, and 6 GHz frequencies
  /// start at 5955 MHz, so they are kept out by the frequency.
  Future<int?> _usable5GhzChannel(String device) async {
    String phy;
    try {
      phy = (await File(
        '/sys/class/net/$device/phy80211/name',
      ).readAsString()).trim();
    } on Object {
      return null;
    }
    if (!await SmartifyOsShell.has('iw')) return null;
    final result = await SmartifyOsShell.run(
      'iw',
      arguments: ['phy', phy, 'info'],
    );
    if (!result.ok) return null;
    return usable5GhzChannel(result.output);
  }

  /// Picks the channel out of `iw phy <phy> info`.
  ///
  /// Internal: public only so it can be tested against real output.
  static int? usable5GhzChannel(String iwOutput) {
    final line = RegExp(r'^\s*\*\s*5[0-8]\d\d(?:\.\d+)?\s*MHz\s*\[(\d+)\]');
    for (final text in iwOutput.split('\n')) {
      final match = line.firstMatch(text);
      if (match == null) continue;
      if (text.contains('no IR') ||
          text.contains('disabled') ||
          text.contains('radar')) {
        continue;
      }
      return int.tryParse(match.group(1)!);
    }
    return null;
  }
}

/// Internal: how bringing the hotspot up went.
class HotspotResult {
  /// The Wi-Fi interface the hotspot is on, when it came up.
  final String? interfaceName;

  /// Why it did not come up, when it did not.
  final String? error;

  const HotspotResult.up(String this.interfaceName) : error = null;
  const HotspotResult.failed(String this.error) : interfaceName = null;

  bool get ok => error == null;
}
