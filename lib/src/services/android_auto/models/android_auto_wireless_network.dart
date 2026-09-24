import 'package:freezed_annotation/freezed_annotation.dart';

part 'android_auto_wireless_network.freezed.dart';

/// Which Wi-Fi network a phone joins to use Android Auto without a cable.
///
/// Without a cable, the phone and the car agree the details over Bluetooth
/// and then the picture goes over Wi-Fi, so the two have to be on one
/// network. Pass one of these to `AndroidAutoExtension`:
///
/// ```dart
/// // The default: the car brings up a hotspot of its own while Android Auto
/// // runs, and takes it down again afterwards.
/// const AndroidAutoExtension(
///   wirelessNetwork: AndroidAutoWirelessNetwork.hotspot(),
/// )
///
/// // The car is always on a network the phone can join as well, a router in
/// // the car, say.
/// const AndroidAutoExtension(
///   wirelessNetwork: AndroidAutoWirelessNetwork.existing(
///     passphrase: 'the router password',
///   ),
/// )
///
/// // Only ever with a cable.
/// const AndroidAutoExtension(
///   wirelessNetwork: AndroidAutoWirelessNetwork.none(),
/// )
/// ```
@freezed
sealed class AndroidAutoWirelessNetwork with _$AndroidAutoWirelessNetwork {
  /// SmartifyOS brings up a Wi-Fi hotspot for the phone while Android Auto
  /// runs without a cable, and takes it down when Android Auto stops.
  ///
  /// Most Wi-Fi chips cannot host a hotspot and be on another network at the
  /// same time, so **the car loses its own Wi-Fi connection while the hotspot
  /// is up**.
  ///
  /// Needs NetworkManager (`nmcli`) on the car and passwordless `sudo`, which
  /// the SmartifyOS install script sets up. The password is made up once and
  /// never has to be typed anywhere: the car hands it to the phone over
  /// Bluetooth.
  const factory AndroidAutoWirelessNetwork.hotspot({
    /// The network's name, what anyone nearby sees in their Wi-Fi list. Leave
    /// it `null` to use the car's name from `AboutConfig.deviceName`.
    String? name,
  }) = AndroidAutoHotspotNetwork;

  /// The car is on a network the phone can join too, and stays on it.
  ///
  /// Only the [passphrase] has to be given: the network's name and the car's
  /// address on it are read off the car's Wi-Fi.
  const factory AndroidAutoWirelessNetwork.existing({
    required String passphrase,

    /// The network's name. Leave it empty to read it off the car's Wi-Fi,
    /// which is right whenever the car is on the network itself.
    @Default('') String name,

    /// Which network interface to describe, `wlan0` and the like. Empty picks
    /// the first one with an address.
    @Default('') String interfaceName,
  }) = AndroidAutoExistingNetwork;

  /// No Android Auto without a cable at all.
  ///
  /// Phones are then never told the car can do it, so a phone paired while
  /// this is set never asks, even if you change it later, until it is paired
  /// again.
  const factory AndroidAutoWirelessNetwork.none() = AndroidAutoNoNetwork;
}
