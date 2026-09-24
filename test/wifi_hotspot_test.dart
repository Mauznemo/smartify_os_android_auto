import 'package:flutter_test/flutter_test.dart';
import 'package:smartify_os_android_auto/src/services/android_auto/wifi_hotspot.dart';

/// An access point on a channel the kernel will not beacon on is not a quick
/// failure: NetworkManager waits in silence for ninety seconds. So the channel
/// has to be picked right from what `iw` says, including the two traps that
/// look usable and are not.
void main() {
  // Trimmed from a real Intel card, `iw phy phy0 info`.
  const iw = '''
Wiphy phy0
	Band 1:
		Frequencies:
			* 2412.0 MHz [1] (22.0 dBm)
			* 2437.0 MHz [6] (22.0 dBm)
	Band 2:
		Frequencies:
			* 5180.0 MHz [36] (22.0 dBm) (no IR)
			* 5260.0 MHz [52] (22.0 dBm) (no IR, radar detection)
			* 5500.0 MHz [100] (disabled)
			* 5745.0 MHz [149] (22.0 dBm)
			* 5765.0 MHz [153] (22.0 dBm)
	Band 4:
		Frequencies:
			* 5955.0 MHz [1] (22.0 dBm)
''';

  test('picks the lowest 5 GHz channel that may beacon', () {
    expect(WifiHotspot.usable5GhzChannel(iw), 149);
  });

  test('does not mistake a 6 GHz channel for a 5 GHz one', () {
    const only6 = '''
			* 5180.0 MHz [36] (22.0 dBm) (no IR)
			* 5955.0 MHz [1] (22.0 dBm)
''';
    expect(WifiHotspot.usable5GhzChannel(only6), isNull);
  });

  test('reads older iw output without decimals', () {
    const old = '			* 5745 MHz [149] (22.0 dBm)';
    expect(WifiHotspot.usable5GhzChannel(old), 149);
  });

  test('nothing usable means 2.4 GHz', () {
    expect(WifiHotspot.usable5GhzChannel(''), isNull);
  });
}
